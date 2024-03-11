(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2024 Nomadic Labs. <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(* This module defines the jobs of the [code_verification] pipeline.

   This pipeline comes in two variants:

   - The [before_merging] pipeline runs on merge requests. Jobs in
   this pipeline are conditional on the set of [~changes] in the merge
   request. The goal is to only run those jobs whose outcome is
   affected by the merge request.

   - The [schedule_extended_test] pipeline runs daily on the [master]
   branch. It contains a set of jobs that are too slow to run in merge
   request pipelines and a large subset of the [before_merging]
   pipeline in addition. This subset excludes jobs that are irrelevant
   in a non-merge request context, like the commit title check. Jobs
   in this pipeline should run [Always] -- unless they depend on
   artifacts of another job in which case they should run
   [On_success]. The goal of this pipeline is to catch any breaking
   changes that might've slipped through the [before_merging]
   pipeline.

   When adding new jobs to the [code_verification] pipeline, make sure
   that it appears in both variants as applicable, with the
   appropriate rules. *)

open Gitlab_ci
open Gitlab_ci.Types
open Gitlab_ci.Util
open Tezos_ci
open Common

type opam_package_group = Executable | All

type opam_package = {
  name : string;
  group : opam_package_group;
  batch_index : int;
}

let opam_rules ~only_marge_bot ?batch_index () =
  let when_ =
    match batch_index with
    | Some batch_index -> Delayed (Minutes batch_index)
    | None -> On_success
  in
  [
    job_rule ~if_:Rules.schedule_extended_tests ~when_ ();
    job_rule ~if_:(Rules.has_mr_label "ci--opam") ~when_ ();
    job_rule
      ~if_:
        (if only_marge_bot then
         If.(Rules.merge_request && Rules.triggered_by_marge_bot)
        else Rules.merge_request)
      ~changes:changeset_opam_jobs
      ~when_
      ();
    job_rule ~when_:Never ();
  ]

let job_opam_package ?dependencies {name; group; batch_index} : tezos_job =
  job
    ?dependencies
    ~__POS__
    ~name:("opam:" ^ name)
    ~image:Images.runtime_prebuild_dependencies
    ~stage:Stages.packaging
      (* FIXME: https://gitlab.com/nomadic-labs/tezos/-/issues/663
         FIXME: https://gitlab.com/nomadic-labs/tezos/-/issues/664
         At the time of writing, the opam tests were quite flaky.
         Therefore, a retry was added. This should be removed once the
         underlying tests have been fixed. *)
    ~retry:2
    ~rules:(opam_rules ~only_marge_bot:(group = All) ~batch_index ())
    ~variables:
      [
        (* See [.gitlab-ci.yml] for details on [RUNTEZTALIAS] *)
        ("RUNTEZTALIAS", "true");
        ("package", name);
      ]
    ~before_script:
      (before_script
         ~eval_opam:true
         [
           "mkdir -p $CI_PROJECT_DIR/opam_logs";
           ". ./scripts/ci/sccache-start.sh";
         ])
    [
      "opam remote add dev-repo ./_opam-repo-for-release";
      "opam install --yes ${package}.dev";
      "opam reinstall --yes --with-test ${package}.dev";
    ]
    (* Stores logs in opam_logs for artifacts and outputs an excerpt on
       failure. [after_script] runs in a separate shell and so requires
       a second opam environment initialization. *)
    ~after_script:
      [
        "sccache --stop-server || true";
        "eval $(opam env)";
        "OPAM_LOGS=opam_logs ./scripts/ci/opam_handle_output.sh";
      ]
    ~artifacts:(artifacts ~expire_in:(Weeks 1) ~when_:Always ["opam_logs/"])
    ~cache:[{key = "opam-sccache"; paths = ["_build/_sccache"]}]
  |> (* We store caches in [_build] for two reasons: (1) the [_build]
        folder is excluded from opam's rsync. (2) gitlab ci cache
        requires that cached files are in a sub-folder of the checkout. *)
  enable_sccache
    ~error_log:"$CI_PROJECT_DIR/opam_logs/sccache.log"
    ~idle_timeout:"0"
    ~log:"debug"
    ~dir:"$CI_PROJECT_DIR/_build/_sccache"

let ci_opam_package_tests = "script-inputs/ci-opam-package-tests"

let read_opam_packages =
  Fun.flip List.filter_map (read_lines_from_file ci_opam_package_tests)
  @@ fun line ->
  let fail () =
    failwith
      (sf "failed to parse %S: invalid line: %S" ci_opam_package_tests line)
  in
  if line = "" then None
  else
    match String.split_on_char '\t' line with
    | [name; group; batch_index] ->
        let batch_index =
          match int_of_string_opt batch_index with
          | Some i -> i
          | None -> fail ()
        in
        let group =
          match group with "exec" -> Executable | "all" -> All | _ -> fail ()
        in
        Some {name; group; batch_index}
    | _ -> fail ()

(* Encodes the conditional [before_merging] pipeline and its unconditional variant
   [schedule_extended_test]. *)
type code_verification_pipeline = Before_merging | Schedule_extended_test

(* Encodes the conditional [before_merging] pipeline and its unconditional variant
   [schedule_extended_test]. *)
let jobs pipeline_type =
  (* Externalization *)
  let job_external_split ?(before_merging_suffix = "before_merging")
      ?(scheduled_suffix = "scheduled_extended_test") job =
    job_external
      ~filename_suffix:
        (match pipeline_type with
        | Before_merging -> before_merging_suffix
        | Schedule_extended_test -> scheduled_suffix)
      job
  in
  (* Used to externalize jobs that are the same on both pipelines. They're only written once.
     Beware: there is no check that the two jobs are actually identical. *)
  let job_external_once job =
    match pipeline_type with
    | Before_merging -> job_external job
    | Schedule_extended_test -> job
  in
  (* as [job_external_once] but for sets of jobs *)
  let jobs_external_once ~path jobs =
    match pipeline_type with
    | Before_merging -> jobs_external ~path jobs
    | Schedule_extended_test -> jobs
  in
  (* [make_rules] makes rules for jobs that are:
     - automatic in scheduled pipelines;
     - conditional in [before_merging] pipelines.

     If [label], [changes] and [manual] are omitted, then rules will
     enable the job [On_success] in the [before_merging]
     pipeline. This is safe, but prefer specifying a [changes] clause
     if possible. *)
  let make_rules ?label ?changes ?(manual = false) () =
    match pipeline_type with
    | Schedule_extended_test ->
        (* The scheduled pipeline always runs all tests unconditionally. *)
        [job_rule ~when_:Always ()]
    | Before_merging ->
        (* MR labels can be used to force tests to run. *)
        (match label with
        | Some label ->
            [job_rule ~if_:Rules.(has_mr_label label) ~when_:On_success ()]
        | None -> [])
        (* Modifying some files can force tests to run. *)
        @ (match changes with
          | None -> []
          | Some changes -> [job_rule ~changes ~when_:On_success ()])
        (* For some tests, it can be relevant to have a manual trigger. *)
        @ if manual then [job_rule ~when_:Manual ()] else []
  in
  (* Stages *)
  (* All stages should be empty, as explained below, until the full pipeline is generated. *)
  let trigger, dependencies_needs_trigger =
    match pipeline_type with
    | Schedule_extended_test -> ([], Staged [])
    | Before_merging ->
        (* Define the [trigger] job

           §1: The purpose of this job is to launch the CI manually in certain cases.
           The objective is not to run computing when it is not
           necessary and the decision to do so belongs to the developer

           §2: We also perform some fast sanity checks. *)
        let job_trigger =
          job
            ~__POS__
            ~image:Images.alpine
            ~stage:Stages.trigger
            ~allow_failure:No
            ~rules:
              [
                job_rule
                  ~if_:(If.not Rules.assigned_to_marge_bot)
                  ~allow_failure:No
                  ~when_:Manual
                  ();
                job_rule ~when_:Always ();
              ]
            ~timeout:(Minutes 10)
            ~name:"trigger"
            [
              "echo 'Trigger pipeline!'";
              (* Check that [.gitlab-ci.yml]'s [build_deps_image_version] and
                 [scripts/version.sh]'s [opam_repository_tag] are the same. *)
              "./scripts/ci/check_opam_repository_tag.sh";
              (* Check that the Alpine version of the trigger job's image
                 corresponds to the value in scripts/version.sh. *)
              "./scripts/ci/check_alpine_version.sh";
            ]
          |> job_external
        in
        (* TODO: put job_trigger here when full pipeline is generated *)
        ([], Dependent [Optional job_trigger])
  in
  let sanity =
    let _job_sanity_ci : tezos_job =
      job
        ~__POS__
        ~name:"sanity_ci"
        ~image:Images.runtime_build_dependencies
        ~stage:Stages.sanity
        ~before_script:(before_script ~take_ownership:true ~eval_opam:true [])
        [
          "make -C manifest check";
          "./scripts/lint.sh --check-gitlab-ci-yml";
          (* Check that the opam-repo images' Alpine version corresponds to
             the value in scripts/version.sh. *)
          "./scripts/ci/check_alpine_version.sh";
          (* Check that .gitlab-ci.yml is up to date. *)
          "make -C ci check";
        ]
      |> job_external_once
    in
    let _job_docker_hadolint =
      job
        ~rules:(make_rules ~changes:changeset_hadolint_docker_files ())
        ~__POS__
        ~name:
          (* TODO: I'm not sure it makes sense to have different names for the same job *)
          ("docker:hadolint-"
          ^
          match pipeline_type with
          | Before_merging -> "before_merging"
          | Schedule_extended_test -> "schedule_extended_test")
        ~image:Images.hadolint
        ~stage:Stages.sanity
        ["hadolint build.Dockerfile"; "hadolint Dockerfile"]
      |> job_external
    in
    []
  in
  let job_docker_rust_toolchain =
    job_docker_rust_toolchain
      ~__POS__
      ~rules:(make_rules ~changes:changeset_octez_or_kernels ~manual:true ())
      ~dependencies:dependencies_needs_trigger
      ()
    |> job_external_split
  in
  let _job_docker_client_libs_dependencies =
    job_docker_authenticated
      ~__POS__
      ~rules:(make_rules ~changes:changeset_kaitai_e2e_files ())
      ~stage:Stages.build
      ~name:"oc.docker:client-libs-dependencies"
        (* These image are not built for external use. *)
      ~ci_docker_hub:false
        (* Handle docker initialization, if necessary, in [./scripts/ci/docker_client_libs_dependencies_build.sh]. *)
      ~skip_docker_initialization:true
      ["./scripts/ci/docker_client_libs_dependencies_build.sh"]
      ~artifacts:
        (artifacts
           ~reports:
             (reports ~dotenv:"client_libs_dependencies_image_tag.env" ())
           [])
    |> job_external_split
         ~before_merging_suffix:"before_merging"
         ~scheduled_suffix:"other"
  in
  let build =
    let build_arm_rules = make_rules ~label:"ci--arm64" ~manual:true () in
    let _job_build_arm64_release : Tezos_ci.tezos_job =
      job_build_arm64_release ~rules:build_arm_rules () |> job_external_split
    in
    let _job_build_arm64_exp_dev_extra : Tezos_ci.tezos_job =
      job_build_arm64_exp_dev_extra ~rules:build_arm_rules ()
      |> job_external_split
    in
    let _job_static_x86_64_experimental =
      job_build_static_binaries
        ~__POS__
        ~arch:Amd64
          (* Even though not many tests depend on static executables, some
             of those that do are limiting factors in the total duration
             of pipelines. So we start this job as early as possible,
             without waiting for sanity_ci. *)
        ~dependencies:dependencies_needs_trigger
        ~rules:(make_rules ~changes:changeset_octez ())
        ()
      |> job_external_split
    in
    (* TODO: The code is a bit convulted here because these jobs are
       either in the build or in the manual stage depeneding on the
       pipeline type. However, we can put them in the build stage on
       [before_merging] pipelines as long as we're careful to put
       [allow_failure: true]. *)
    (match pipeline_type with
    | Schedule_extended_test ->
        let _job_build_dpkg_amd64 = job_build_dpkg_amd64 () |> job_external in
        let _job_build_rpm_amd64 = job_build_rpm_amd64 () |> job_external in
        ()
    | Before_merging -> ()) ;
    (* TODO: include the jobs defined above when full pipeline is
       generated, as well as rust tool chain and client libs docker
       builds. *)
    []
  in
  let packaging =
    let job_opam_prepare : tezos_job =
      job
        ~__POS__
        ~name:"opam:prepare"
        ~image:Images.runtime_prebuild_dependencies
        ~stage:Stages.packaging
        ~dependencies:dependencies_needs_trigger
        ~before_script:(before_script ~eval_opam:true [])
        ~artifacts:(artifacts ["_opam-repo-for-release/"])
        ~rules:(opam_rules ~only_marge_bot:false ~batch_index:1 ())
        [
          "git init _opam-repo-for-release";
          "./scripts/opam-prepare-repo.sh dev ./ ./_opam-repo-for-release";
          "git -C _opam-repo-for-release add packages";
          "git -C _opam-repo-for-release commit -m \"tezos packages\"";
        ]
      |> job_external_once
    in
    let (_jobs_opam_packages : tezos_job list) =
      read_opam_packages
      |> List.map
           (job_opam_package
              ~dependencies:(Dependent [Artifacts job_opam_prepare]))
      |> jobs_external_once ~path:"packaging/opam_package.yml"
    in
    []
  in
  let test = [] in
  let doc = [] in
  let manual =
    match pipeline_type with
    | Before_merging ->
        let _job_docker_amd64_test_manual : Tezos_ci.tezos_job =
          job_docker_build
            ~__POS__
            ~external_:true
            ~dependencies:(Dependent [Artifacts job_docker_rust_toolchain])
            ~arch:Amd64
            Test_manual
        in
        let _job_docker_arm64_test_manual : Tezos_ci.tezos_job =
          job_docker_build
            ~__POS__
            ~external_:true
            ~dependencies:(Dependent [Artifacts job_docker_rust_toolchain])
            ~arch:Arm64
            Test_manual
        in
        let _job_build_dpkg_amd64_manual =
          job_build_bin_package
            ~__POS__
            ~name:"oc.build:dpkg:amd64"
            ~target:Dpkg
            ~arch:Tezos_ci.Amd64
            ~rules:[job_rule ~when_:Manual ()]
            ~stage:Stages.manual
            ()
          |> job_external ~directory:"build" ~filename_suffix:"manual"
        in
        let _job_build_rpm_amd64_manual =
          job_build_bin_package
            ~__POS__
            ~rules:[job_rule ~when_:Manual ()]
            ~name:"oc.build:rpm:amd64"
            ~target:Rpm
            ~arch:Tezos_ci.Amd64
            ~stage:Stages.manual
            ()
          |> job_external ~directory:"build" ~filename_suffix:"manual"
        in
        (* TODO: include the jobs defined above when full pipeline is generated *)
        []
    (* No manual jobs on the scheduled pipeline *)
    | Schedule_extended_test -> []
  in
  (* Empty placeholder: this has the effect of not overwriting the pipeline file in question.
     Once all the jobs in these pipelines are defined, we will return them here which
     will cause the pipeline files to contain the definition of all those jobs.

     Until that time, all the jobs are written ot external files
     (using {!job_external} or {!jobs_external}) and included by hand
     in the files [.gitlab/ci/pipelines/before_merging.yml] and
     [.gitlab/ci/pipelines/schedule_extended_test.yml]. *)
  trigger @ sanity @ build @ packaging @ test @ doc @ manual
