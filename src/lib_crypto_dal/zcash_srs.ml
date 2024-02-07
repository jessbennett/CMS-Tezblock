(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2024 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(* This file contains ZCash SRS for DAL’s verifier
   This SRS is suitable for following parameters :
     slot_size between 2¹⁵ and 2²⁰
     page_size = 2¹²
     redundancy_factor between 2¹ and 2⁴
     nb_shards = 2⁶, 2¹¹ or 2¹²
*)

open Kzg.Bls

let max_srs_g1_size = 1 lsl 21

let read_srs_g1 srs1 =
  let srs1 =
    Array.map
      (fun s -> Hex.to_bytes_exn (`Hex s) |> G1.of_compressed_bytes_exn)
      srs1
  in
  Srs_g1.of_array srs1

let read_srs_g2 srs2 =
  List.map
    (fun (i, s) -> (i, Hex.to_bytes_exn (`Hex s) |> G2.of_compressed_bytes_exn))
    srs2

let srs_g1 =
  [|
    "97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    "ae3f321e2ba24e302542a3ecf8847e8e820f9ca1b3a6a63bae25140f215344314e1bfc9c36bf2c3dcbe94dec33d71f3c";
    "97695f2ffbdce27015ddb180c97c48ee65a6f4f1e887143ffa10a90f1ea6a4e4ca1986e0bf270b11e703f3f4285b8f29";
    "807175300ad2593ade55b142020b72705a2711e53573e2587c4dbe934bb7b1350e7b808b4cd4d7a6273616c904132e21";
    "83e8d6b123cc80a0fcb7822bb4e6f3daf9b622f78a6f002db4f74b373c3645ace01f4a729456c6401098ee6f4fce0ce8";
    "8e5306edc10ff8f66416eec6d46fcede51ed8de4ff3cc5bfb22a0621082231b96e1fbb62e6e8872079e1d8d8bc68ddef";
    "8d5c70a95235f317738369922232cd1027db73c3566e50067f098317574b6991e4aee9089d8635964f967c84812bbd2f";
    "96fe169d864cdaf674ccb5b03e4247a3244c23483005b7e83771f7062136712374823a2d0a0ae8c32f9d411d77f73639";
    "af0471fb787ee97d1481588b9525317ec0c4bbf8877da2d767176061cdbf01e254c4f8a626bd120f04578cf3167da856";
    "853847d5bb534a2a2aa915d7d44c9cb9b946b55d7c235223718321bc02d54348d3868487e8cce9c6531fbe96b2a79626";
    "9245962c288d3d0f4c3fc9c74634c58019b591ce6a5f5cd9a72c5a0df94c7d99e22ad0a7315a1feaf221f4369c0bd2d0";
    "8bb6d4a46b804145c1de9ff9ddfff3e1fe37bdaf329e72085ff5e216e0f41c5f2cba7473fb9a11351fdf8bfedc2a5c2f";
    "8ad6bb2b7f638845f5d9df580f39f1a0789497ae711685025bd869342209b51901ca3ffb8a245e0429f2d0d18f36befc";
    "93233455fd4fb7a410eac2cc28e734501f21133ef5ccfa5ec888170583f506401b5a0aaf581b961c6be660f35cadbad1";
    "8850f03b3fe1e402ae906bb3e6390dc0e06e77ab1a4aa896aa3e97148433c78f131b1fa254da302c3d2e3eed0f59af3f";
    "8ec2c243115198badc714b1a8cfe406b883733bdd5fd765b043ca8c6d1c0edeed2d9b06db38fe6225db0b80c0e0f09e6";
    "ad6aa2730c4553552581377c80a592b52186b8eb9714f56cff4f9f372d9ee9a6c5c8b2074f73a93e603ab7edd85bf3f7";
    "b751d13ae7929af33443b2097fc618d301a2afda4212f51d0386dddbfc0c6d132bf8bc4e3a0f56556ccbfd2be73a1c4f";
    "a8728adb2c9c4a1715729ed9f3852a753cb5f5984f740aef1b4d02e2edcafac10a3a0f3a78e1f9843bf29f95b10c0926";
    "995bae0724697e0d9181f82ec28d499777765d6100ccb0d8ec1d9629b1b8f6cb108ef25857d4fd4e029aac4c53ffa47d";
    "a36510431dc45ecc4bcb2ca6eea7c3f2ed3175462011090442e36b5949f7a52c7daabc518498b09c3aba7cd24e2de36f";
    "986f31ff3e6f962649e05d684d257091bc6f8e231ccc9e9f117cf6d596f0b06ecbcba2fc7b65d56ce616837fedb24fbd";
    "806dc5b7fe845d2ccfa408f0a3cc8590103251c93f658aa48e3e76aa011f096edc8f78711af4dbfa6b495377f592efd5";
    "87ca0e26a5e2eb6585524c4a3462116631a58e0476cf285299e5fb8a67d5f289e155206413d39c03ceb0174bb87b9d89";
    "ae107986db909d19f2f8dee8c4925cdc4c7da9f92b3aacbd01336a69496c7bf7b870784b2d76ab38ba87ad5b30eb3fe0";
    "9371778e7b3029b2ba8ca10c0e91e0b5994f20a989b234a8260bc66fcf48553206d716e32db8d896b41c1a84abec9aa3";
    "aaf1f0659f29b8be0b59a28c291fb04b3df6664e6d895661b15369e0cce22f3c8af9c626daa3fbf71a294158ab6af0b7";
    "94061db27129d047090acbe0050fc1c09b410f024b72fd7bb7d66c28eaa4651b97d4b4167e1186d97a0be55fd5383762";
    "a7d5369a62be255a52cd239d68f2ee1650ef894964b1b15e032a354c0695db78f3e1ee6071abb97be5441aa3495ba9b1";
    "8e2dac868a69475ebfad50e20a722de0c4117b5e99ac28ee97667c73e7357b63fc69dd52ced9b196e40eb67833933d3a";
    "843d74589c101afec85b76a49cc012a5e7a8dbaba8208041abaa7951a4d979879b919b4a80a116bdab5f1ca1b538858f";
    "a76a376c12c7b3a63ddc9228c794fcf662b816badae842db32cb789bdf50ffa2f8dcb17f7cc1c036b0ba6f8d93e5e69c";
    "97902efd2aebde4775de19afcf03b8695a6f676346b593e3eab915244f550e3868a1168e567044944e60233526ae7018";
    "83a708211746a51df88dc3d7d408dc53ab984b88fa2115f428cd54322ccddb161808fe1d42395604b819bbdebc580240";
    "93edde4eb94fcf5ecda8e0aa7d79f193bfc36ba6563906cb4c8fe770efedfaf6fe63542342556513ad4e93963adc381d";
    "a055f4f449e0ec123016552e0e43d00988f19aaec494b6d62967904d64cf84ee97f74d3ef20d67cecfcfe1bfb2bbdb85";
    "912a2a175869ac93764a693ca45233745d23f63511e8253f97cc9ca81a5a930c14da48e6c6ce0b274bdc321f32b021c7";
    "8af07a8d36252bc9bdbe36bfdb0811c724a1eb06c5283089dec607f4a4e90bd09f1048c51697e5a29291eab5287c8313";
    "8201813c47c290051796dc75378309bd2e8d6439a84af9b729c579e576834e0e70ac1dfd476cbc044caee9f401eea516";
    "b9625583a53c3909f79589f9f558d468b93f53297d0c29b7af8ae5aed29b73888ff8d6d866514309f3f0c38ba9fad981";
    "abeb9b116fd54061dee87504df9d7e2dbe6202c4098f1a944c807ea2afabca92f4b624b4952ed7adbee8ce8bc2212f64";
    "aec9ec46b3e91148dfd66cc043224ec31ceb3797c624e350cedd364dcdb4bec9ecc0ca3b325cb61ce8fcbdad2cca55b4";
    "b0de2d6a82a19d9a0ec9dd49233d11c3affe851579777bf6cd0878d26887735a45232db2c8f423aa875c7de111f4127a";
    "8947612ed6f96f962538dd856b1493653ed611d82643bde93f4b8c5c7450d81648253116f3d41d53ad90fb5bf8c067be";
    "b70f442eed6e5187c3c8425ddf32f5bddbd9377f7ffaae276ff45fb529bfb3c38af2624a28be5736c4ef51b094ebcf52";
    "8c410a8a6f373e633ca1a8e47b1de489f18822fcd42a1b72f62ed99fdcc6fe4da8522a6e6a2f251276dab181ba9a1a4e";
    "b2b21200a057e98718cc45fc6930f35fc8e41ec6fcf3224ca966e860329a45d502f75a757ee974084e6502efbb3e26de";
    "8ee8187961e322a5b071664aea6f74bb033139232f7b2e4e2267d4d24e62e918ed42e08886a3f79d1f2f18c1b9f86c37";
    "a311d91411ab40e71e4b8fcac1003e31b043e4db29d7977cd4b6e5d6165649f332a0743f8c2a7479e0176a78e5fd84be";
    "8dd89499268af187f23d5e0778fcadc308a285fffbf3e6803f4d358c9ae5ac56d419621dc3350d85c6502b23f76879c5";
    "b7eff65a1780815842ad21137302a7224e279dc1f8393636bb4bb436754bf5bf1c1f2dbefaf40745cca8b0e76e4ec2eb";
    "af8c6bb81717d6162461bfc6ca128e5b06db075ceea7e8dd2088a9b3cd64ba25b5309956dd00334b6d875d8afd06b15c";
    "b50a2c502526868c4724149e56b0cb03fd133f68113bca9d2fff05f2300f6c5552083579945081c866240c4c3feb6360";
    "80d1eca1bbd3d6e520a6aaacd3c91c4ae3d23f661ad4c5f9ff3034a62fb52c1dc82cf3e190cd6f65e140dbf4d7f87f9f";
    "b3e25416ff4e650a0a296213280d1ce1ab9e989b241c2243893416b0fef2250ee3c508dcedc57b1b6dd79ad4b696ea32";
    "846c8b9ab2a464241c56176c18a14692180a7caa15c4347d5c4d1193ae28c7498b54f72b0746f97858b7dfd17825380d";
    "a4c01a7fee6c6eb64de5be8d009069c12d6b2f0f217cd82c16c0fb8ba243bf24b3ba774ca9587fda6d6116bd3bf86097";
    "82a96e20725b7f5dab8f36b4f9d0b1ec7c33e5a5489f2ed2d3eb8bb9e95f3456d878b9312557dd7c117a99e16e3e99ed";
    "8c77d5f88dc9b3b0f59647fb9a2e5b5971638bd8e065101157204cf8b997015fdd77f64b0941ca70a3f8b2f9529fc2f2";
    "b5db143b12195f3caf47a58037c598956040a3790b2f7f7316470339836e9d3753d4dd320ecd8258dea8ad3307e487bc";
    "83a29591729ac9231d903231ddbfb3f93a70c8c6b2b81052b4e491f7cac94a55e105b2b4dcfcc249973c41a9356b72b2";
    "b3b936d62cff885764042d7861ba97b7a112df82288304191da59a57a3b7819041203bc545fe7d7c0048c809dd5677f6";
    "b267a43b1cbd64ecfa912e6b21b69493f801cc0de48564b400a882d64ddb862529e8c2f60db507e109e8bc97c75564a8";
    "889de8f480ed1711834b9c9345cd3f3f12b2e85e04c9c3b0af2e320cf651c3f0810a14595e246037cc5859d4cadea81e";
    "a8edf47e4fb801060d8608013770a58f9fce90cd998b86562706872f745cf7dd19f39d7bbfc841d362d91c467f2ec88f";
    "800e0f265b595b06af4d27842236fceebedcb3e677f3e8441116e23f7ef5746a6482872dca7094ac226736b49b1777ae";
    "b5d5178f70da2a73bfcd35607d1fb442cddd6586fd2435ef4eabeff771764ac5f2da0e0043ab4df677f5c677827de1ec";
    "a5364d239b673426ae93b2e553da577d633731edc3aeb22c87ac41984a90fed14556cc6e0e04204aa77bc74bf03faf74";
    "a86eed9dcc39fbc8c75d941a3e99fc55c1e37700e3ab006d779578f44738abe109f5b08f69c8a49136f954bbf79253a0";
    "ad4748b14e03b75769d7395c8530f52e1167c89da8f66990b5b1494bcc60fd8f61043fff6cd78c6b8805e14ca8c5f79c";
    "81f1f276ee701c1fbc11201ee489bedfe005a489a5e66ce378fe455fd913853015480fd22ea438aab8f0a9b6cec7b067";
    "810585d2349ba6c4394a7396db8022b535e227043a246a9c8f1c149501bbcfbd5122203d744790f2ba796a6a2c2c6d6b";
    "96d0041cc0dbfa63db712ae837ce2a18a024233a30ed1d30fa2590dc3b8695adc284668568bdaadffb30046d4f005d7f";
    "aad2fa1e79ba957df5b425e6113cf745ef0e5d05c358ba68e3ffd9e84dae428a198efe886618e3da229459c49ec930cf";
    "8b007fdf4bf8f454e4c83268ae10b98534a72665631224e27c8bd056d04a57f63fa0d4a3fa590c6b872e72439c7c3e4c";
    "82896aef49f4ae976cf358b911b0e0465273364b199f9d1eba4f006f410ab19c49b385c7da5d7f53a85e957852f07654";
    "8dd2fc3812c69b39013ca2fdb71d974f0801c7708276551c61462de8e16239ad09cc15eb772ff6296cbf9f5a5bb8dc0c";
    "96ef289269fad0264a0c8f6889278e089ee415dc11bac38de73ec2bde658f1ae112491803db2cf4bd5e4561c23e3c312";
    "8d0dba7c31ef3ef8c2e30d9c629fb2cd9c87d77c14e92322299efb76b97ef3171b2317cc34eb2f3dd1c4f23bea1391a2";
    "8e9db7bf43930a6a046cbc3bb4d3aa8c9f9ee662c82998d3675a00fc5bee40ed446bfb0a3d7fdc04e2ac5f526f9078fa";
    "816b851f00bdd8bb5db68da2d821624752d76baff0110566775dd89d71a755929a650ad278f867b0996ee25855bb0243";
    "8a92dd5a07379d7aa9fee315c19e3a9fc84332b2be56602de7a5a269e061644cfabbbe396c6b451d7dc350b483b0a11f";
    "8fc630a6f8cb24fd2152cb1f964569ff7b74eb9f32e7dbae33a6fbd871c1fadc10a793b5ded19fabc10a7c5cbfa60c45";
    "af69216b7058c64c0a8102760c8a38168a98d2a0f11c40be0cfaf48e89419428efa20ac62d5c5f419bfb82d293b651ea";
    "91f640902a09c5d8c68acff42617c5af66895d6e9c3d783af6d6a5abff7a18e6f62866293bcd6b4de6c0aec68c56893c";
    "87382aaaa7616862ed005d35d943a95109ec91decfb7d5fe4ef3543bceb3d744e4077341706e8147a18bb71605017851";
    "80ee00ba37a8efc17632f202d509c81eec1c8db7559548c067c7b94b790be5921a3afb226f13aa7f9875082eea9d5bb3";
    "a9d4dc4a7f6b94ccf7ea62f777dc57d3967acf0322f4b962d4c46c478d69d6c18f04a286cf2cddb1a6edeed96149e825";
    "830703a11e8872017b97632caa8f6ce5430ece3b12d73ce310b6e96cbd5a2646a2cc126c5b81cd0cb79a3849df51da8f";
    "92d07dea9c39a91c0372a415cfbe881eb265b9cc6f767a3c90d564fac96625284c5cd050c75ef0d62451d33e83aa309b";
    "8ab89fc205425ca7da53a3995812eb48c6ee5325ad185313abb9501af6365b7ebd9ecdaa0b3f54f23f7026fef44d4859";
    "af6793b168ac1fa1dccab79644142da12c3ef4eb23ef0d0a90cd9dc8af12dcdc9e7883a717d394dbed43bc7583967f18";
    "a5075f98ecf82268ad7190a632014fb0271df4b6aaf888380141d67af15294fd8ad8d9b75745320f74a86e778f1ec392";
    "858546d09e7f67de147313bc7e1ca8fff00c66787437045ddb38e19e9cb0169a95731d37f6e2e0ec58d1f0438b3307ef";
    "927756304bfdaf32a47ed7f84ecde31cf812d666f38f965f1153924b8f68ff18e51462b52dfe0cae1e5d9cb43a4e3949";
    "a29dee18c3018b55868485124bda3a03826c11bc24f2fab99794b6e051944c25a98cc935a469750f8178af0109b9abeb";
    "ac90ec4a46b86c5c803f929f4ff95458436db29e285f475620604506cffe24c8c277b611557a7964cb33a98b883fd9b5";
    "82e36ec5f9b14770e8bc8b7dcab2b5a044c954696242c6b12fe0f45b7ad2db6a6dd33241554db70d64910fcae50c2eaa";
    "8833568231581b125ee9368d22a2166df3ef5c80f750ba0a09214c3b6608403cc888d029d023cc32992555d1293cef60";
    "996488ce1bc08cfc949f810976b3f591691ac7d81bb266a057e0d9770f5d1ed16eb1639141400d3cf879704da2a07e23";
    "af053716424df6c1ca18740fb86c17839f063cc585e5457468861f8fb981bf230ad7afe4aafd8588e14a39a390a7c13f";
    "ace5613ed724e4a4c906d2b06a29be74f5bbda1ed0fe94e9f0e1509313cfa84e7080c9c7b14438d1bd71d38d0366fa08";
    "8fc81bc21816fa5bc5853d203e9250eb10f424230c0f7212a3a346861d50e02e3ed89e051eebd2de3160b427e4a07487";
    "a1f90c47f5a50a88ba21555d13d2c42482c56871485537c9b9e661b7ca3e7af27f8ad52f249ba8bbaa8d0b5f13a1d001";
    "a579c2bf15cc330e96595731c34d529d7cf0ba780082e0b5432fe78050118a17c6d9a9c77527f0d4eac4c49b2b758ec6";
    "92a5b63802d66f6b0efdca8194f88ed848099cca672281b3cfc707e1ece745c4a851462b4855987b2b72d9852c2bafec";
    "b3764c82ae946bc27eb7fdb7e8e2947b4575d9de8df6faf70537de5f3997264a038e771f6d71f8d9cd256539fa359d0a";
    "ac752065837ac473e03ab6b69ab97006198b0aa9f2ba1a8bc73662b9439a4101705bf3ba9de561485ed58f3fdbdc6f83";
    "a23da5f33faba5d41c429a737071fd8454ed4caf68219e090e55067ea36fa28d5b768e5c594a1ef3fd6d1e052e9a9096";
    "b692c39da980b47d2aafee08b544940e3f57d8e0383e06c2f97e7682b7449ca3507d9185396d66a9ffb04cb041b04550";
    "a41c562b3a046672cfc63ed4286de4af44c9b7ac8a97317b9ee7c235eec25a7a448d293dd19b4136514fde32567c4717";
    "afe97c9462f5b5714a855569dc42c1635367e7a6ec039d83eed5d7acaa296a0109c6316bdc636a35568bda9fbc1fb20a";
    "92ce6a0c04fab877b6b0259d750cb02811894b0574c189ae7a1e0a0282273c3b8e903306870b535c70c1252622d78979";
    "b46d7982bf61e416bd3651f5821b687787eeb2c886433a542b5420e02e8e6a76231ac6a233affe31ee69afeaf0588b1f";
    "b5eb895b5ee00c0c604179244a579012c352845cfccf90af9e99e2bd53f653d808f5a68ab5b3ccf51d6be13c63222c7b";
    "b6a985acdb55522795cf213fced3eeecdec35cd0b5f8e1e311b5eb573d1287b0f8b0fe9c5dc0fd82d49848feaf16d4f9";
    "b3cdfa840aa06441bc82d8852d5249c69298ae8b7d37108ed03fc6180816290a8a3b4f7fe2df0a7e0716d01245fd79fe";
    "b46310304857c15dd04302f75ad9ea0339d31377e461abcd7b0ce653b4a9b6319f730d0052316bc36d434472d5c4a5eb";
    "b708675e7ae554c24b642e172706032eed21e0339780ef73566f02a44390d2da13e4c718c566e43dea43928ada79deea";
    "a6efcba4c9560983713d7f66996b0db9a1c430b11392d3c904b40e7c59caa26889f52abcd69f8443e939aae20f8d2075";
    "83f0b00d597d3fef63ddb5406a9088525bab0386970ab7e9da09a89ac90480e258a71c21452273507bc4aa2d2280e389";
    "a474cc3e7fb8b4e6d9d33473bcd2a3d62a090c1840883fdd7774d51700205e23000a25cd85cba7e341539c56cdb623c6";
    "8aaf9ed5baca4f00952eade1f7f8371c2117a615abeb90be04bebb8760570041fd6811c1ba329ab887844ebe84e23c04";
    "ac4ce9d7ed4a2b7753e1ee0eea6bae2ce46df0093fc505d044ff19bafb4cd15101d4f6c47527105ea906600788663d66";
    "8c9f3ad1114e8167bea7655c51f69a8c8d9171b99040a04618e6006a901d9aabdf96cb6e54d951e22501ca0089191ae6";
    "b59ae999869f295efed4a5f6936f29d7fd7a326cb4bbd37350b8d27fa5c8164107e819bc598cf39b7cb97de7d3a56172";
    "b3b2eb0fa4cdc1140bab2fc5cab7d161d0b31a25cd6279f7f90e65f97bb49f17827760e7fa5924d3b8075d9dc124899a";
    "8924b7a85f242c559a01f4be9fce5b8725dd04ab55a7fb7bf6fe77d4f157d91ef5aa0e801b2b1fe84011ce0205d357b1";
    "b3f79e2d932e8ccf3a026407068ba5b34e265feb829b0631556947f37471b4647edcf837c1670f073fbe7e27385a2a66";
    "85df4763c6e7c9f69331c645bda8e3c3d0e8f272c40db2117acd7aacf6e8760d59819dfa5f5718a795fc54a872e6562a";
    "aa1e35cd31afe90be5998fbccc22e9ad64b29540a39971e3afdfd30fd9d81189bb5796b88db6e9b0dcb48df9d3e1ee4c";
    "96066b8b8dc6d11627f15cc95b93f284fa43ba38ba2defcc005b4f5143c339d9122aa965b6d2a153d929fcaa67f83d07";
    "977b35e6d2bd3e3aa0a4b3c4c7b6c0e724199a6188d23b57901564476114982cac140482b881042f21e007cc164fe418";
    "b0f589b512ed5bb4a4209532aa28d4a29162181f259f82885435255f5ce026c0d2373238e3fa951c39b0ac16848a25c8";
    "87b4929b717cec25a84aab387f0bfeb6485393d146db1e76dc85a2faeb894fbd68dc3e55ad59970dfdb6ac94b2cd1b02";
    "860d7b40fbaef807504b363ddc5a5563d8df065bfb454df289ee560f14f5b0e539e317979d9a6eb111b0fb91eb33d677";
    "b4bf946f4ba558bdb226d2445c3fe1af2c4488b8a23c15398bf08fe95275482489a6bae76ffa8e5ff16622305dad1339";
    "8cd23a303b50d4a0f6cb4fb285b9cbc017e6e086df274f724eeb036203c95289753bb7ec645c07ea66c31dce1badd7a4";
    "aa8861cfa61e7d936c4cf5f9889bf54acaf6d996e3977de1285a7007527a9c785e328c25e215bac35b952251f8cbb103";
    "940a3c68016b24e9f10579f8aea0678c450c15995f7316762758f251904ae8a369d339b6f16cc194dbb29af0e0ce9d8a";
    "992200148244242736e073b9ce62ff19402e4f93f824a3d469e601351dd79682dfef3a65e09df277570637d9ed8731ad";
    "a9e8b308b35c0a7f525c74e451d4a221e6fdf13b8e6a40cc96cd55a607ac56bf74d161a1f689db3fa31da42c03b453b6";
    "908ad1c0ab9561990f5ddbbc9d8971cfdfae163456aa8dc83f10ede9b5c81e7609cd8bfbb8b2b9fe96421442e055b271";
    "86027b5c3d0816afb0ddfae2e84ceee6a7f5e334f9b1b29cf4c5679029845c6ed842c19a1fe24b9b848cca3a49c179e7";
    "b07d50b8937d53462a83752d7a9c1db33fdd4f5fb2c5bf99277211dd1671e26c31f13667be0585afd5ae070f2b59a187";
    "a9c47920861ed5a6b16d7b0d3af53f275f2c3b3694ee9c58c6bd8de6aa85d876081c6c988106c2aeafd83b33c1244e20";
    "a952b3df3cd2c134724be08cc5fe1a09a91f688de8fc3a6d9c4f7c7dbd3770277a43972690850703b0b6cc0580a7858e";
    "8aafc9f4185df5d683add8f0ca8e629cb7374d54cda8a238e994d902315dc277a478be036bed175763991473b91b656f";
    "b30bb0e8a3b9b1c8ff3470e9d1ddc3a912d1a797534bfbade452df81a03016c935a229b596e68e02240ba66b4dda67b1";
    "90970b3e61945e86d66c7e95244dc2810e55c0b962e443fe9656514904e7ddb3864ace7786e92bbc2e0c5a3684d553f2";
    "8f4416c46ea3f9af957ca5aabf665edd45a655a873cdb7d1410525750d1c75c9096d176c5ad7fa4d1ec6128ddc1a911f";
    "8998a1077911ccc212cb309c2c83dbad8d203a8437c11ef46ee060d50b2f0975880d8e341d04997f3a2c262d24c9b35d";
    "aa58f6b0ca52473de087649fd83ecddaca1eef7483947f8c1cff02870f6e8280c536256f260ccbe034b03125201cca99";
    "b375cab3c8cffa8d1291b0a0ac7f4cdbf36936d66150f4f85407b00eaf44ddf372ebd8dcc1a9869943cd8496adea23e8";
    "8bb0cbf8cbc3ee74efe55c705f2adc8ae75f0e67311a076303042660594c6625445a61a4759824c92e552b3099b4783e";
    "b5f6aa9a30105af363c144f42b57f482a2cab64f70189c77b060492e592c91145175896d5fdf0ffa25069c239b281aa6";
    "9719d26c4df535c88c74db1f8d6f069e77d97d09bc7611aa0467e0ea28b02da598dfc7f144477d8ef18ad9c6886977d5";
    "a0d55666a9718d734ae2a0127dcb65bbf9770b8aaf589c58652b1321829d7d6b284b391a1b5cafc975ce908a92c5b264";
    "8d0e5c1b059ae564813658f0af3e7c642e7925bc9f27a129b227c4474543833e56025846293b5d4586bc8cd5b6b66d23";
    "8d8f9151890b725512f6876d1d36681ce86b98bb3129452220580667382ab2d747aaf2204a767d3803d7974c26e42e89";
    "b35df3f622b10cf05a7a33058052d0b66ce9bfca2626c6fc7a75284685d966bacb9dbbede5af7c299ac16cb74e0f41ff";
    "87b5d4000412014e1500ad79127e0698d3a11bc85057286f15ead25014cb970236895ceb65eecfe8c7974e4cefcbf0b2";
    "a973cc6cd8eb00bd2fbc4eb13872f8814cc3cd1ebcfc76bdd937cfa138b3ea510fb84d4701778d62818126059e17213f";
    "98802427f229185af301cb82b15108265188be56994721c3d5c35933ccb6336af7e6cc8b7805f89a6c08b1a2617bd6b0";
    "83e28197c627f91020a254eb8a62ac10fc3eb22461f6e3480ab72114166b7c016f688d0fde712de1082cb344cd5cf802";
    "b941868bb3cb64b74b03687c9f0934d171f8ba6747204cb19eb9c6cf5f759cda075cf35b1e3b3d597cf6b20e64a39d5a";
    "abfe5f908eba89d4cd19e4182f48b29a2f90e00fe723c7b3de25db4875248d109cc06e0ae71c0d067af9f9b2b9e793af";
    "90e155a3ad8d0fdcca15ed3948320ecc806f29264f9eb5954f01e5fabd9cdb4b6ea18ff9c06f071c8a746dc4acb43fec";
    "8bc303f01bd0c1157164c1751c7012c102ac394c3e02851435eb01518aa76ce2da9be258b29a86c7358c428b2915faca";
    "b75fa2149e3503dff0c5c258afcd44b84a7682505d734f589060143b47ea69bb1fe99d92a3597ac450a3935ca19a6ec4";
    "86a8d3839cf32430ecb33cf04f25d98078ebc254033157ce0157c5bde84913779a8244147bc5e7e2d7356d9c74de8708";
    "98cd7d9047c5ab8951da1ab01aee3a1de20d6ff3ecbd0158666dad559f77797a786a5de1a4278926611f65903efff26f";
    "9895604303c8f13ece4679eb0e88c45a3ce75b3fec6f99e9fa6c59fa86242f5fadcbba60a3b666e2d98d3ac0f48dd1cf";
    "a4b7e6723cba4556ed9e8ccaa8b3fa54315ba2276d0658515d9d5e95c1e0432b6efbb21864a7e8b0567db2203fe88801";
    "ae65e8f44107e77bd3d8f1772238d5b3aa866f5ce488c5e92cc61d306d9f1c9dc2bcf6965d34e9075055cfa19e75b68f";
    "8a11cac145972e25b14d14ffbe3bf06f952659c6855fbc4cd094f45b5db960cef94a2ebb6003a54768b5cfd82ae8c180";
    "ad797a827901a0bbbe2d28983b211e4f2a0d3d9e32d44c5becec771f695bd4cb664df9a0a7bef30ce5b5e1efc48f19c5";
    "9529707c120b651e407512248f3384a01f822f9d2d3bd12f29ed6ab9db9722d1c460f18a6c26ae2eb718d3d11f7e615a";
    "b1786e0a1f2e4cc5e3a47a1268209633d6eb1b472229519b91f62c8bd31d07e8fa26f794c26d751ec8166d134542a254";
    "8c1a9d5161313287b3be670fa6e6a0fe8223eff6cf727dbaa91052cbb44a4380777c10aa40a770e392905b4126c53dc2";
    "a9e905595dc3aaef8ef874cb6b2cd7e686d278772208a8a3cdf6f24b5c5568e66863189fcc136f44937dfe502144b426";
    "a3b6cb0fbee6bb46144690e7511e884231c6a5a52ae5940fb4fcedc5557d9d1aa762f55dc9eb1a8ca8bf0206078e9988";
    "a836900e29aa15bd092590b0e419fe570638ab8fc95d6a47926c49fbca2ca334805ce1547a588df87c642b5286c76b24";
    "82c19e77636f4311de7af38ce3e9c6bc99854ec7aecdab62faa892cbc4410933bf65a0af7ed25f25359be7db6b0d01ee";
    "9743eb16bbe5608e7ce6b65e4170903e7c4310a63f34be19b3f89d30dc53f0ffd4b891ce526d4c79214e6b80a5ebd098";
    "8958ab4902325675a61a66ff105f0f5c46d770aec1e885dba4d1a638088d2a8ec80694ec60ce4c8cf1cc89296de089eb";
    "a9b9bf37363f876610e73f1abcbfd419ff2b5b6ee2442297a3ba6a0c8d5cec139554352f70e5bfb59f86e8c54cbbee24";
    "a7544a1d6c6f588067462131aebcba284ef8a7b2962d1a7f2a59eedfef38dc539ab2600e35fd7b5f2b3624a60e035111";
    "94b691dcfe4e479866ae33d821cfdc11c9f55e6e7aba18cc7fe1f72d03d352de030543c6a0ea03274f3d6762cdf6adf6";
    "b3662b6168094f6c6515fbb7dba8234276853ae583a8bf40fe477dfb9da3cb54c6dbfabba46ba0536009891351f9fbd3";
    "abe1a9fe90f530e7e2c1da3f7b891752c03ec7410271f6736a315b84a75aaab6058a9c1fcb856b7d5adf2d07f3438aff";
    "b1da1900fe731961e6819108cfb53e48866eeae4aea834b8f64f99ea6f8da0746c058c13d5c3077262a9795a2875f268";
    "82db70aaa0aca483f6ff93eef7c48272b0c0814d9c06bfc24365dca930c679057f057974791a7a66c4ead2306f210127";
    "95c31508983b431a49d14ebb5f0e7cd572bfda26624718d2c000d1fadb224adca4defcde58820d98f2d742be0ea7eb59";
    "8b926266fa93dfda5f88e652de84a09fcfbacd9032bc6eb856195205927e1e0486ad2365bf183c479d52f77bb5901ee0";
    "8b85f1c26c2deff4bfaeb99ce28a9086a5a940e4d03d59faaf305936ddccdb9d9ef7eff1e5b1361b0a32a3aebdabe951";
    "a9034fe508391f4114afc7645a4691dd428861417217c24874ab03b69b1e6840eb0c2288909bfc8d599f97c6f81460ca";
    "8b9e9cfd00c975031d5fb0b3064f524ac3a46c28039c005f8ffa5114e8946174b55c7c9e008b20eabb5eca20d8dadecc";
    "8fab56be77d316f1fd6663e16820e2974c52c74546308500b091a651b24748cac31e1a1a6a7f7584503fe41d76d53e9c";
    "864f44793521f64fbfba68c73750bcde1c64de2068cd8901bacc312c44a17237f1f22042bfa561d7bea2d2a85e2e203c";
    "926540a955c0d758598672ee3fb11a99c467840b6b72915ea5c208e0889c59dc4fae36ec0cb9679711acf275aed5c3e2";
    "b3556b7de265e7fbcf639d8a64ed89e4bf58cef8a288bd5628d3b95bd37273492ec09dc33d2ee69505a38184f2e0a75c";
    "b2f3a28a3b6fb6f27125c6d7ecf6865c0c11c6c53c9e1b0654a3428cbd2a8f3bd8acebd62f39bf4c635089bb393c1a72";
    "a3b3c0b59e1907eca957da49b19a21f5dd3ff46d46cfe3cde8330f88f5132058e3c13293f66c9363255227721f84c166";
    "9922c109804f20f62ae0cc5ee8040a5d84c3f163418b7cf168de5abc6a7b0c822e6b90baa47eb35198b0d9b52545a2cf";
    "aa14a8dee946dee8104b940c58eafafc5969cc300499f827fc2417dacc64199abd9c4a57ae640f7962a1dd9db45da26c";
    "964bdc5b7b947c864fdf6c4b783e2b2daaf4c35f58afea3795961f5ff1335da02c11adc2eafb1cd30a9e1a5a4a3cac66";
    "88d691822caef4980da28ef171a2d546b292201d207da427829dbc153cb942ed24331ba4a6058c4fecf2a950c7c6520e";
    "83d57b2ecb93c58d2cf05ac5013b72ebc610cf94529bbc08fb54eddd0f9e16156881167ab10da7bf57f0a5b7ab441634";
    "b75c8a68f7420c3d770121de39f581178735f97fa9fdd01064656d1884a164aa3b2003d2468d9c0af371af713b8e289a";
    "b80bd1200fbc016912b1dacc27d3b1830657f204f810c17705f4f9f81022aa52e05a6b69a60a5bcb8cb8a8a09045498e";
    "956eeb76e5bbfc30c4ab1390dee52da977a3be1e55c53b50cbbd2b85e768b223754f70395d576065d47e9097b90a502c";
    "a8ed1992014cf4c11e11accdfea71ffd4a518a283ec6c582664c7942cfd21d095f1ef6c9addef183c7ab1118931dfdc4";
    "b0c0f234f622caa9d6ec60d1f9c3c64a595ca89baaf8486ebf07b6d2aeedf269cb65321ca2937ae94e9d14aa1f35893c";
    "8df7b1f4f28829211193c83feee97e4cda2803d9e8a406714581e64780c2734ed34b5bd6d09f3a5b0dcfe9d5ec603802";
    "a3b84aa8f87be4cdefe3ccc39f4fe04fa5ae715714b4dde78eb7e242e82f12fd77e1008c2b7ba9eae616429202c39f6d";
    "855a029c45d2a22ad29dca4a3c4ec683924b2f4d9adb505e924b71de0c095b073ab5929c9df8483636061b7862408226";
    "b49a92cb7b1d65c8e152b33949cbb0ccccd2f38b7c1bd078d84eab1b7e3ff00996d01801bbc2ce2cc8f5a4d559dc440c";
    "b6280aba7d7fabb58e17c2a52963246ed581726678d006ec4e2ce88bd6f99dfd0f533b151c9a9cfd59a061def42179f7";
    "92bdc132005ee539061e5403cabe5646b9f58c94d7de135dee43de58042474fb1768011565f12d3cf72b0225752dfd7a";
    "a3348ca09104bcbb0978b98d1047bf0df4938a5eab2f7b5d0404f44bc8446540d2b724d2ecc20659249d8fb26c758bea";
    "8ad2d141fce9e5800f21fa4b025d94251d2dd6858a084cbdf987122e6e33a74c47c190fde8858b753efd07c432d50720";
    "8fd6c4ea2c948a03e98adfe087cd31bf1acb8819d94c9b558f46aae5518dd967e9ac804d7bbcef3cc98b58b7015260ef";
    "8631b770dc6ca4d832333e9dd80dd0a69465b855ddbce9baab9065f475fdef97334cfcf2d7bde89dad4a8a5f4c1d0e34";
    "b64835593fe1c292342361bed556f52e31925c46106de5a6cf7ebafcde8fe522343d69d63004c514c04721494b11593e";
    "9253c6b54a8530e063f8a2bf809278b67880f6449b573a9e7128bde25a23abe58832dafde789457c344b10b23dc7ea63";
    "b8dcb3dd9653a0d6ec92f88c2cec5015de5cd33615483340e41e283757d8f848cdb8ce3e2ce0123a330bf6ce46141648";
    "a1dfce1ae94d0f805756f86128b5d4ae3ba5e3e91b87d2a15c8c334310959308c845c3365a380f8cfdae9bf3c7aa69a6";
    "97ecc1a066ccdc83a92a22688ab98d6b3410ce5a395ee5cce53a37bdca0f3da9fa3b1d52733d219057e236eb4e30c62c";
    "a072f0f85aeb85be1e8b945e81091f6cfa4d46b9cf30c23923c1911442ca4b4c1239f9f53ec48820e2194bf4d21f098a";
    "8d79ac2e8b8f2cc9e3690cef51f15e0d78ae3b434c75d31271447d440584c16c1a0296369118a574035e28ce6b62a713";
    "ad94c06b74cc30fb7dd42cdfba78dfd801aa0632994f81aa7960089950c8db92819d50424bf9c44c5bf4bc24f79ce588";
    "8318bb208c3091ba9492ccadd529ee4bf8e10307002365831b33f58adb5d9f3bc52893bd8057ccbf5510389a99e2bb3a";
    "b2d823225611c0c2bb01bca496faf8a7957f661228cb0ee6c0c5536cb5af8000ba43a6f28aca5a3cd6fc12d10399de39";
    "a0f3e2e5318bc54e1bfebe90f0b4a568b63b3c0dccec2dcbfb54a30bfc9763a2b0d17de2e44c48f7599ef8e607550d41";
    "a6ad2e45dfcfbfe88cb3fcb01ff768945f3e1897bfe48aa5c6d8adfce160dbdc81bfb49f64241418a22b31d6b1712328";
    "8717a8ef69ac0a61e3dd04639ea7f4b7172221f3fe570e745cbac2f0345b3ec54658806e35291b4facef0246067208f8";
    "b291390187c72d3f244aabcc1c58195a15984e3e5b8cf0cfc81e7e544279c0d2691afe13b19d3efd1bb3ee2903d76da0";
    "9317716da3d0782ced0ff6e72a92c2db314bb5f2d831c3de68175c702e51dc6fdc843ac234e286b457a9905565c531bd";
    "a1f3fb56dc29a84c3df96ab84d7bab657ff34fe49d818c357ce750c827e6d273e63a42109fb9c3ff5bf21c1bc0efefe8";
    "98e47a69ae000b62414121df7c48224e5dbbd865b0cb9d5a5ec0bc71fc55ee9df718fc19a6647dd367a2a098a40b82d1";
    "9654ce283c25c0e796c0e89d52f5aa0073e27ef97d2cd50692db6d1eeccd9a0ad54cd2a40dced301e798bfca744bf040";
    "a6aa1b2e777c1d5edee9817682fa28ec6ffd73eca8ffdfd5deee8210dfce055900916a4ab8d70846d7e8c7a2a4f22304";
    "ae2f24d073abd32cc2ba2ad7ae1e5d69c843b8fc9270a22d76f3a5bf13876cf8de1475937e64ab5fc12c5063e0b9b052";
    "b266a26ca7f8e65c76b58c1d3f223aabd88f24685a015b0e37526f419759aac4d972282724a33c40a18dc862680cc746";
    "80a66d1b6bf9a2693b6a9f1e35347439ea7048c9070d66ad0dc62fd534f2907115abfe37fe4be0f97c86aa8d4fbc6e8d";
    "ac512edb9d36b9b53125a27cd6f33221673b4d9d90bb02755c1eb59b06eed155ee066d0cfaa8f5088a43ea9741423081";
    "aec172b24da87dac6e6d7d091a08ba74d2bae2a030149d01de66a999e7d2017258e096de80e0ae5e9ac654e67eba0797";
    "8209430eb036316c49c686b3fd89603db6115be6ebb1ebf9fbe259e2be76280b4afe6cf7936b818d9176134b06e13db6";
    "a46b8509e52e7d4fe15fcbec10cbfc9ac01d0c104cd7ff871e5c8c08e40a4d3cda830fc65cd922bb8f4cda0dec7f6d08";
    "b9ceb1f7f8407b009735d976a363f9717213f2a753f8ec6eef0cd5c0a7138273f998eba66879f32e0a403db020c6cce3";
    "8b316b185b6728fdabd6e168df0ed611f3c58b473a3805ec7cb1293d39f954a850042181ac11529a5fe1e079850ad736";
    "83f2f22fb17c5295348c1b7206ea825dadf34313819c1fb55e8378315613266fe1803757095e56c09f29efefeaf45e64";
    "99bc7f49fb019ec2877739dda6c686cf7d9117f8dd3a6344d8f47f497478d2dd6a563b9cae5ea8faec74ad2653ea049d";
    "807ef3a37c7e55a6d19513b63afd430a45ab6de37f3815d3f648a11146fdaf7b222ec8d1a004da6f9602e1022ab04f12";
    "a838016299beaddc5093e14f2fd8c0705e7142133d4cb6bb9afe935b26ab8e79b4f75df70b5df4cd6300d885a54543ef";
    "b76fd879a14794ce73ba8904d360ba49f4eae39432238dd63e032feb36f9f5fef6c2ff844581e59fa43ecfdbd50ae73f";
    "af9e464f12ae8c12d1aeb0aa26f282bf4c11e47cae0268fe538f0ad13027b7dd9ca7b5921866a7e0b300b35e7e21f7e4";
    "8674a880e6a10ee96d6085d7bb282147a80126cd5f017309377e158893e8c79a0b404a2786c1bb34f7352b804082f3b4";
    "873eb5f46e319bd090482ecf1aa6c66805acac43bb1173ab95fe2855ef5ac337bf07f4fb231526014d30c65a71e7ca04";
    "97a6adacf3d2fddd967bb4fb86a640c7bfbcc9d0496eac9ee8cae0113dae27a13b67fe926c37da5ee40a8d3a32c3809b";
    "90cbce16bda37a64a8c07321bfe82a2912b7409b07de86d68978f5d82e98a43cef804d58eedf124dd3cbc375a6fbcd32";
    "ad75621c68c163d59a06ae0e66cc157f20252a75be03c2966d3393c66b9e3e3b4a842b5f597eef9f5b010c345bab9161";
    "abe802b6dcee4cfa10675442c03a24b38d8efadbb7d0d64fca739118d1c7d18c9272810328b9982800be4c3e95ee99ad";
    "91b49c2072794843caaa03156749c4e6010de2972b9eed92c8f08f74a0ad0cc1c5fe7e740b4bed23918f1fc0a2b63243";
    "a06f22d4ad4db567a0603cac64af2490e60c86bec8756354b99aa8234bbe71fe34049e956e448bb742a142d4c25970c8";
    "9188fcf4e3a6d6413d2bedab29b9b85a9fb7e0ef1c6cd42aaba4cf2f9007ec67d90dcd4c660b544ebe61e4682dc53241";
    "ab0fc95d352363dee3ea16163a705d5634561c167597710945b11b3f6c3034fba302aa35ae95443370f3310db8c77003";
    "aa66311cb561066dd11b9a7832499b4f6caea7d1344c8f7a9734f52c41ec3a0ec996bc4a0183e16ae6f932da3af6a851";
    "8bf2900b1dc59c081018e0892bc4b1a0d0e7c1bf23e37840d6d82e5e0acbfbcb7ad100e5bc4d0e8af814304421a4d31a";
    "a8d49dd52986d1029c90d5a0a4492b813adb7377ad93aea93297b81b09c947e85fadeaa8eadb7d2c5191ac20393b62f1";
    "a7372c7df0800ca59eec555492a309838879dd4ba835e3022ac293e7cc6e665684816f42ebbbb4ae65342d7e7ade460a";
    "953f5c8cc9690360f88cfa855e1b8ff2f214a663bb8a7c35cb7b819e2612d8210f1ae915820585743a30a821f174fc45";
    "83fd4abccdc38076732d17ada1e3b6320a7c2114238412b5dcaeb415869b6691cb8d806773142ee58c50ca9da8d15a7c";
    "97a6a9fa6d32ca8d5e4c1908382d847333fde3a58b2d6549b42486b115066e4e466665caecb81bc24595374fd7bf8845";
    "a88cddd23cef1c8333022cb24cfce602c7787c112c656d37e564d912267af2b93f8972e77134101c5d72e1478cf154a9";
    "af50fe8cb9f723d3986adb2476d229aedd14b1abefe15814d7b35e2c017667ca358e7b24c392a71ac59e145ac51d5de0";
    "8b11b18f4e6cf87bc84d4455d3b9073778b8d5708fec45731685c5864f85b904f3dbfff9a64ec922a4b1f97e717b6d30";
    "96b538f1a2a4196853d78cfd9ab2622ae731d76fa32bf8fbeea528c54ed7bf79dcd80df10a8ea49a987d2080236b583a";
    "b6d7461a13c62d1186422df7a178ff97fe0fa8ada4769c55535527cc8c0b2d8890be56df10d0e8dc147a1d23bf28d6e6";
    "943300543306e2f3248fb4e0a9cec8b774c6c326b5427e95b1874f565c37908922f57daa58a81100d60493c92ebf4dfc";
    "926d98f8a1b2f4ed2bed4732776cbeed3b525e052c8a873360446e796a3d2b1182b90b6dfc6709097287eadc05524539";
    "acfa46dc7a3b7f450171e3d3f7bb63309f757795b28acc77e6bf4cec81efe1b1c12c9d83d604d026a1f4d501ce79795b";
    "94b29a50dd48b50287a71051e3ab0d3991f2377844b3f42191c1786a6d9698b6e5986040493759856743bf6fbe9ae104";
    "abb3d59d9fc9c4bef262bf59a3ebad5119b72a84392377d2ddb50185ea4ea35c11d1c3bacad9b0b530afc809f1846c71";
    "a8cab93febb0806443d1d7a3954efe63675e74fb0d1472f088859eea2bd16d3b3552fd13c26ac91824af633ea18fce6c";
    "b30ffd219090fe6b68ee2066966ee868cb32ffaada8fe155c1fc36f3dfb4ed2bface1e10db0a48ccb7a50c8d36776cee";
    "ad1acfb6505d0b4124adf46d2fb2d3b28423d57db80313bf470e10d7c5307096c3a1b95467ab982c22c610e896bc9dc4";
    "93c0ffe8207eb2fe4ed15332825085317db4f0a2ffc5b43d2eb5d5689ea2a9952385eac82c225b4efc5e25b5a3f0a594";
    "9011ca17679e8c669b6b47641a1609e37884296e0c4537ac7f2e055a972237cfb1a0525b452085ac7eca6e41f6553f19";
    "958eafa9d108bf81f4836addb16b2eb5f21ce11183389fd5f3bf8e354a9e726fb8085197802fbb79cad6ca851e08dddb";
    "b51c5d8e473eec177117370fdeac1d732b9828d16caceb2f1682d78076c36d16b812fb5ef24896ac14b259b181545a4d";
    "a7354cc6bb2604cb86b83a83f04f49194b9ccac6e45f044bc73d24026c8e983dfad9c090383a6e760af22405b35ef48e";
    "a20050f986046d4dc806f1bca93aab60cdd736b749bf216b953fdf49c61cda9c31af10c4829b89c16e7a11b73c0b7ac2";
    "ab7e9d94e52bf837889d048e239ac66c2542788b7f65d687d6c76b1763f7b999f2cededd6c34ff6c0245b81c9b5e048b";
    "8463fc4ee7e03a3b1c02bac2ec2db8d2253fd6594057508658ca7625e3e268b85c4ce91ded5976b267de8a6b56ef1062";
    "a56d9e92b75a4e800af8c16b8baf769b17e43e003f133eb304253fe9f794dc9f8dffab98088a9eebbcc6bf079e641917";
    "8b738ecc278e50c167f2e0f13d76f93bafe64b3bdcd4bab0c7e0e00cfdcca39d8bfb2fc1e003ecfb156823e9df62c3ab";
    "859d36519d3db8a3d38dd495aef9992c9cc9cc78126cc64a544bef6200865bfa9972e95b046ed445f890f94909e0059c";
    "83d361e911b1c6a75bafc8a5096b652826d3eac61bce9a887ac9b5656ae80de9eec25725fdb9be551c1a70ba808b692d";
    "ac1f97fc3dde14823131320a40d2b16ba04f00deb4486598daf0c69d463bde5b09044626f7d068569528af279a0fc436";
    "b2637ed013e66ecc264199d41749f8d20c5a19263129bc6dd1cc5a194882844d1aded827ea948c4e9c278265afadd129";
    "97e0118f0b198a3cd48cfccbf7d628363cc94395f28359b375a5fcec007f0f7f9e39bcb00516f1e47a18a78d956d11fa";
    "8d137b709677b8943c5b677616115166c79a119d18f173d398736ce900a947a4152221000d486ece71c381a6de9b5de8";
  |]
  |> read_srs_g1

let srs_g2 =
  [
    ( 0,
      "93e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8"
    );
    ( 19,
      "98e7d3f1fb528bd8f981a6f1ea9be1da47e9df70aa2dc53942765ada276f9dc690d5dd7b4c4da5518c381c938a32f55a119ccd181b36a36dc070d21bfbfc9fdb55318f96abe9608f7ca5c0cea47b263de3979f9ac154fb7d81ce56647236068b"
    );
    ( 38,
      "8fc5806597fe04f5f4576d6c2160d0fb798417cb3eac99c0ed02204de743ec312dd01c7926188096413a823e53ebaae2035770f1ff20eb73a3501faae76a792c787f1ea2a3508ee4e563327833a1a614a1ddba069d14761d89ffcf697ac2aaa3"
    );
    ( 76,
      "8bac994404aabe461b8d11ad37b8bdfe835f97e592346a0d0fbc10d6d62d80828c031c81997afdc562b5b4d53d2e912900c4d6a8d39683a21f30fb033037e011aa7cab5191c0e03f3564bf5adf14d5013c9049114cff7da25e8cb99a59fc1b05"
    );
    ( 152,
      "ae550078b1c2aee47f16851ae1acaf02e3f650dbacb838ec1f6c864e35464d4211ff582af38c7284a648fb6515095c34059fb874525de5744b143eaebd448588dfa15b3b35a6870d965865ff48766303c4d597c284a75b1543da4d0cc987c481"
    );
    ( 304,
      "a2610c7d6f621296df69e69d976c7a8449ad84f1d8932cfb6f9c6626c5db4b88d99ca188dfcc9b7b9ff8cc157db7c4b8131bd94b994218af933ffbe18bccc6e2a34b047271976f697807402275951470fc85921f3c6aedfa0cf5aef048a27b32"
    );
    ( 2058240,
      "90c0d222a6fbe54ace06027a9e75b7a9f2873d6b1729531e1f1ca5d102d16373bc00e82002047bf41170b05c499e1c110dedb1e3563661c0e0ffc382f833333c4f594273ddbaa895db73f6f97d4d7bbaaa2d7a43238827834ec473563a33d70e"
    );
    ( 2077696,
      "93334aa883c30b6cb3b74c2620bb37a88de97f719955ef85e27751607c15331beb551d37ca11c4258edebc663f64566a064bbba505f3016775a93581527ca451268ebbbe7ef10f7287614e9471cd736f15e838ff7eeac5008ff43046ed4a67ba"
    );
    ( 2087424,
      "901920051e5fa2ad72281d8f174b4da97325fd023af48d19443839433834177f22412b5b6206b85157ec6ac7be9219f416248bbf43bddcb1280ee0e49503844bc864170c5e7c72d86c195379fccc6363537da9f9865b3343329e2a0e3e594a9b"
    );
    ( 2092288,
      "b731d654a8c9718877b4410a5d9a5c1216f450a9d6d1be168be74c15fa6d703bfaa92ad03b96ff09dce1d7e54672389104cac7618226a2abfaac180bd760f8389f836a4b43ea07b12001d772811a243742bcab5b8b8e847a61e1d479617067f1"
    );
    ( 2094720,
      "b0701aeb96cb9b73306dd56b13b8c175df65f358f784700772e837d1ce26f241485e199327d04e8d7bac6fbe57569671148860dfe9dcd5542710ec95b8dad21b921ee664f55f1a936571a3b2a1d3ac733e322fed6ec25eb221978fe84cc73a7f"
    );
    ( 2095936,
      "99bae1a3f4670e273f8cbce54f9c99d775901badda690acd5abe0c70f0c82756af2542f48b7b55d04730dbb2889555561246d52fbfeadce0a347cd9cc03981ef066402841d333c8a7f289ae5fbc26a446e44514e4b1488bb430a5b131b18b157"
    );
  ]
  |> read_srs_g2
