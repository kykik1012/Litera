import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/shared_pref_helper.dart';
import '../../services/user_service.dart';

class EditProfilePage
    extends StatefulWidget {

  const EditProfilePage({
    super.key,
  });

  @override
  State<EditProfilePage>
      createState() =>
          _EditProfilePageState();
}

class _EditProfilePageState
    extends State<EditProfilePage> {

  final userService =
      UserService();

  bool isLoading = true;

  int userId = 0;

  int role = 2;

  File? selectedImage;

  String? profilePicture;

  final nameController =
      TextEditingController();

  final namaBisnisController =
      TextEditingController();

  final deskripsiController =
      TextEditingController();

  final tahunController =
      TextEditingController();

  @override
  void initState() {

    super.initState();

    loadProfile();
  }

  Future<void> loadProfile()
  async {

    userId =
        await SharedPrefHelper
            .getUserId() ?? 0;

    final response =
        await userService
            .getUserById(
      userId,
    );

    if (
        response["success"] ==
        true) {

      final data =
          response["data"];

      role = int.parse(
        data["role"]
            .toString(),
      );

      profilePicture =
          data["profile_picture"];

      if (role == 2) {

        nameController.text =
            data["name"] ?? "";
      }

      else {

        namaBisnisController.text =
            data["nama_bisnis"] ?? "";

        deskripsiController.text =
            data["deskripsi"] ?? "";

        tahunController.text =
            data["tahun_berdiri"]
                    ?.toString() ??
                "";
      }
    }

    setState(() {

      isLoading = false;
    });
  }

  Future<void> pickImage()
  async {

    final picker =
        ImagePicker();

    final image =
        await picker.pickImage(
      source:
          ImageSource.gallery,
    );

    if (image == null) return;

    setState(() {

      selectedImage =
          File(image.path);
    });
  }

  Future<void> saveProfile()
  async {

    setState(() {

      isLoading = true;
    });

    try {

      if (selectedImage != null) {

        await userService
            .uploadProfilePicture(

          id: userId,

          image:
              selectedImage!,
        );
      }

      Map<String, dynamic>
          response;

      if (role == 2) {

        response =
            await userService
                .updateCustomer(

          id: userId,

          name:
              nameController.text,
        );
      }

      else {

        response =
            await userService
                .updateMerchant(

          id: userId,

          namaBisnis:
              namaBisnisController
                  .text,

          deskripsi:
              deskripsiController
                  .text,

          tahunBerdiri:
              int.parse(
            tahunController.text,
          ),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        SnackBar(
          content: Text(
            response["message"],
          ),
        ),
      );

      if (
          response["success"] ==
          true) {

        Navigator.pop(
          context,
          true,
        );
      }
    }

    catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    finally {

      if (mounted) {

        setState(() {

          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {

    nameController.dispose();

    namaBisnisController.dispose();

    deskripsiController.dispose();

    tahunController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {

      return const Scaffold(

        body: Center(

          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(

        title:
            const Text(
          "Edit Profile",
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(
          20,
        ),

        child: Column(

          children: [

            Center(

              child: Stack(

                children: [

                  GestureDetector(

                    onTap:
                        pickImage,

                    child:
                        CircleAvatar(

                      radius: 60,

                      backgroundImage:

                          selectedImage !=
                                  null

                              ? FileImage(
                                  selectedImage!,
                                )

                              : profilePicture !=
                                      null

                                  ? NetworkImage(
                                      profilePicture!,
                                    )

                                  : null,

                      child:

                          selectedImage ==
                                      null &&
                                  profilePicture ==
                                      null

                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                )

                              : null,
                    ),
                  ),

                  Positioned(

                    bottom: 0,

                    right: 0,

                    child:
                        GestureDetector(

                      onTap:
                          pickImage,

                      child:
                          Container(

                        padding:
                            const EdgeInsets
                                .all(
                          8,
                        ),

                        decoration:
                            const BoxDecoration(

                          color:
                              Colors.blue,

                          shape:
                              BoxShape.circle,
                        ),

                        child:
                            const Icon(

                          Icons.camera_alt,

                          color:
                              Colors.white,

                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            if (role == 2) ...[

              TextField(

                controller:
                    nameController,

                decoration:
                    const InputDecoration(

                  labelText:
                      "Nama",

                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],

            if (role == 1) ...[

              TextField(

                controller:
                    namaBisnisController,

                decoration:
                    const InputDecoration(

                  labelText:
                      "Nama Bisnis",

                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(

                controller:
                    deskripsiController,

                maxLines: 3,

                decoration:
                    const InputDecoration(

                  labelText:
                      "Deskripsi",

                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(

                controller:
                    tahunController,

                keyboardType:
                    TextInputType.number,

                decoration:
                    const InputDecoration(

                  labelText:
                      "Tahun Berdiri",

                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(
              height: 24,
            ),

            SizedBox(

              width:
                  double.infinity,

              height: 50,

              child:
                  ElevatedButton(

                onPressed:
                    saveProfile,

                child:
                    const Text(
                  "Simpan Perubahan",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}