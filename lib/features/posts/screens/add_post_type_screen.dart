import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:xabe/core/utils.dart';
import 'package:xabe/models/community_model.dart';

import '../../../core/common/loader.dart';
import '../../auth/controller/auth_controller.dart';
import '../../community/controller/community_controller.dart';
import '../controller/post_controller.dart';

class AddPostTypeScreen extends StatefulWidget {
  final String type;
  const AddPostTypeScreen({super.key, required this.type});

  @override
  _AddPostTypeScreenState createState() => _AddPostTypeScreenState();
}

class _AddPostTypeScreenState extends State<AddPostTypeScreen> {
  final titleController = TextEditingController();
  final captionController = TextEditingController();
  final descriptionController = TextEditingController();
  final linkController = TextEditingController();
  File? bannerFile;
  Uint8List? bannerBytes;
  List<dynamic> carouselImages = [];
  List<List<String>> taggedUsers = [];
  Map<String, String> taggedUsernames = {};
  List<Community> communities = [];
  Community? selectedCommunity;

  DateTime? electionEndTime;

  // Flag to track whether the share button has been clicked
  bool isSharing = false;

  @override
  void dispose() {
    titleController.dispose();
    captionController.dispose();
    descriptionController.dispose();
    linkController.dispose();
    super.dispose();
  }

  void tagUsers(int imageIndex) async {
    if (selectedCommunity == null) {
      showSnackBar(context, "Please select community first");
      return;
    }

    // Get all already-tagged UIDs except the current image
    final Set<String> alreadyTaggedUids = {};
    for (int i = 0; i < taggedUsers.length; i++) {
      if (i != imageIndex && taggedUsers[i].isNotEmpty) {
        alreadyTaggedUids.addAll(taggedUsers[i]);
      }
    }

    List<String>? selectedUsers = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StreamBuilder<List<Map<String, String>>>(
          stream: Get.find<CommunityController>()
              .fetchCommunityUsers(selectedCommunity!.id),
          builder: (context, snapshot) {
            if (snapshot.hasError || !snapshot.hasData) {
              return AlertDialog(
                title: const Text('Tag Users'),
                content: Center(
                  child: snapshot.hasError
                      ? const Text('Error loading users')
                      : const CircularProgressIndicator(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            }

            final users = snapshot.data!
                .where((user) => !alreadyTaggedUids.contains(user['uid']))
                .toList();

            return StatefulBuilder(
              builder: (context, setState) {
                final filteredUsers = searchQuery.isEmpty
                    ? users
                    : users.where((user) {
                        final username = user['username'] ?? '';
                        return username
                            .toLowerCase()
                            .startsWith(searchQuery.toLowerCase());
                      }).toList();

                return AlertDialog(
                  title: const Text('Tag Users'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search users',
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text("Or manually tag:"),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Enter custom name',
                            onPressed: () async {
                              final manualName = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('Enter Name to Tag'),
                                    content: TextField(
                                      controller: controller,
                                      maxLength: 15,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter name',
                                        counterText: '',
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            context, controller.text.trim()),
                                        child: const Text('Tag'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (manualName != null && manualName.isNotEmpty) {
                                Navigator.of(context).pop([manualName]);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 300,
                        width: double.maxFinite,
                        child: ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            return ListTile(
                              title: Text(user['username'] ?? 'Unknown'),
                              onTap: () {
                                Navigator.of(context).pop([user['uid'] ?? ""]);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      setState(() {
        while (taggedUsers.length <= imageIndex) {
          taggedUsers.add([]);
        }
        taggedUsers[imageIndex] = selectedUsers;
      });

      for (var uid in selectedUsers) {
        if (!taggedUsernames.containsKey(uid)) {
          if (uid.length < 15) {
            // assume it's a manual name, skip lookup
            taggedUsernames[uid] = uid;
          } else {
            final username =
                await Get.find<AuthController>().getUsernameFromUid(uid);
            setState(() {
              taggedUsernames[uid] = username;
            });
          }
        }
      }
    }
  }

  void selectBannerImage() async {
    final res = await pickImage();
    if (res != null) {
      if (kIsWeb) {
        setState(() {
          bannerBytes = res.files.first.bytes;
        });
      } else {
        setState(() {
          bannerFile = File(res.files.first.path!);
        });
      }
    }
  }

  Future<void> pickImages() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (res != null) {
      List<dynamic> images = [];
      for (var file in res.files) {
        if (kIsWeb) {
          if (file.bytes != null) {
            final uniqueId =
                "${DateTime.now().millisecondsSinceEpoch}_${file.name}";
            images.add({
              "id": uniqueId,
              "bytes": Uint8List.fromList(file.bytes!),
            });
          }
        } else {
          if (file.path != null) {
            final imageFile = File(file.path!);
            images.add(imageFile);
          }
        }
      }
      setState(() {
        carouselImages = images;
      });
    }
  }

  Future<void> pickElectionTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (pickedTime != null) {
        setState(() {
          electionEndTime = DateTime(pickedDate.year, pickedDate.month,
              pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  void sharePost() {
    if (isSharing) return;

    setState(() {
      isSharing = true;
    });

    final captionText = captionController.text.trim();
    final postController = Get.find<PostController>();

    // Transform tags before sending
    final transformedTags = taggedUsers.map((list) {
      return list.map((tag) {
        final isManual =
            tag.length < 15 || !RegExp(r'^[a-zA-Z0-9]+$').hasMatch(tag);
        return {
          if (isManual) 'name': tag else 'uid': tag,
          'isManual': isManual,
        };
      }).toList();
    }).toList();

    if (widget.type == 'image' &&
        bannerFile != null &&
        titleController.text.isNotEmpty) {
      postController
          .shareImagePost(
        context: context,
        title: titleController.text.trim(),
        caption: captionText,
        selectedCommunity: selectedCommunity ?? communities[0],
        file: bannerFile,
      )
          .then((_) {
        setState(() {
          isSharing = false;
        });
      });
    } else if (widget.type == 'carousel' &&
        carouselImages.isNotEmpty &&
        titleController.text.isNotEmpty) {
      if (electionEndTime == null) {
        showSnackBar(context, "Please select an election end time.");
        setState(() {
          isSharing = false;
        });
        return;
      }
      if (carouselImages.isNotEmpty &&
          (taggedUsers.length < carouselImages.length ||
              taggedUsers.any((tags) => tags.isEmpty))) {
        showSnackBar(context, "Please tag all the pictures before posting.");
        setState(() {
          isSharing = false;
        });
        return;
      }

      postController
          .shareCarouselPost(
        context: context,
        title: titleController.text.trim(),
        selectedCommunity: selectedCommunity ?? communities[0],
        files: carouselImages,
        taggedUsers: transformedTags, // ✅ updated format
        caption: captionText,
        electionEndTime: electionEndTime,
      )
          .then((_) {
        setState(() {
          isSharing = false;
        });
      });
    } else if (widget.type == 'carousel2' &&
        carouselImages.isNotEmpty &&
        titleController.text.isNotEmpty) {
      postController
          .shareCarouselPost(
        context: context,
        title: titleController.text.trim(),
        selectedCommunity: selectedCommunity ?? communities[0],
        files: carouselImages,
        taggedUsers: <List<Map<String, dynamic>>>[], // ✅ adjusted type
        isCarousel2: true,
        caption: captionText,
      )
          .then((_) {
        setState(() {
          isSharing = false;
        });
      });
    } else {
      showSnackBar(context, "Please enter all the fields");
      setState(() {
        isSharing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTypeCarousel = widget.type == 'carousel';
    final isTypeCarousel2 = widget.type == 'carousel2';
    final postController = Get.find<PostController>();

    Widget buildMediaPreview(dynamic fileData) {
      if (kIsWeb) {
        return Image.memory(
          fileData["bytes"],
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          fileData,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'carousel2'
              ? 'Campaign'
              : widget.type == 'carousel'
                  ? 'Election'
                  : '',
        ),
        actions: [
          TextButton(
            onPressed:
                isSharing ? null : sharePost, // Disable button if sharing
            child: const Text('Share'),
          ),
        ],
      ),
      body: Obx(() {
        if (postController.isLoading.value) {
          return const Loader();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'Election title',
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    maxLength: 30,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select Community',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Community>>(
                stream:
                    Get.find<CommunityController>().getUserCommunitiesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Loader();
                  }

                  final data = snapshot.data!;
                  communities = data;

                  if (data.isEmpty) {
                    return const Text("No communities available.");
                  }

                  if (selectedCommunity == null) {
                    final routeCommunity = Get.parameters['community'];
                    selectedCommunity = routeCommunity != null
                        ? data.firstWhere(
                            (comm) => comm.name == routeCommunity,
                            orElse: () => data[0],
                          )
                        : data[0];
                  }

                  return DropdownButtonFormField<Community>(
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: selectedCommunity ?? data[0],
                    items: data
                        .map((e) => DropdownMenuItem<Community>(
                              value: e,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (!mounted) return;
                      setState(() {
                        selectedCommunity = val;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              if (isTypeCarousel)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        electionEndTime == null
                            ? "Election End Time"
                            : "Election End Time: ${DateFormat('yyyy-MM-dd').format(electionEndTime!)} at ${DateFormat('HH:mm').format(electionEndTime!)}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: pickElectionTime,
                    ),
                  ],
                ),
              if (isTypeCarousel2) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Pick Images"),
                ),
                const SizedBox(height: 10),
                carouselImages.isNotEmpty
                    ? SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: carouselImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            return buildMediaPreview(carouselImages[index]);
                          },
                        ),
                      )
                    : buildEmptyImageSelector(),
              ],
              if (isTypeCarousel) const SizedBox(height: 20),
              if (isTypeCarousel)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    carouselImages.isNotEmpty
                        ? SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: carouselImages.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Stack(
                                    children: [
                                      buildMediaPreview(carouselImages[index]),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: IconButton(
                                          onPressed: () => tagUsers(index),
                                          icon: const Icon(
                                            Icons.tag,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (taggedUsers.length > index &&
                                          taggedUsers[index].isNotEmpty)
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          child: Wrap(
                                            children: taggedUsers[index]
                                                .map((uid) => Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.6),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        taggedUsernames[uid] ??
                                                            'Fetching...',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : buildEmptyImageSelector(),
                  ],
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildEmptyImageSelector() {
    return GestureDetector(
      onTap: pickImages,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(10),
        dashPattern: const [10, 4],
        strokeCap: StrokeCap.round,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.photo_library_outlined,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}
