import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'util.dart';

class ProfileController extends ChangeNotifier {
  static const _nameKey = 'profile_name';
  static const _photoPathKey = 'profile_photo_path';
  static const _professionKey = 'profile_profession';
  static const _genderKey = 'profile_gender';
  static const _bloodGroupKey = 'profile_blood_group';
  static const _companyKey = 'profile_company';
  static const _designationKey = 'profile_designation';
  static const _departmentKey = 'profile_department';
  static const _phoneKey = 'profile_phone';
  static const _emailKey = 'profile_email';
  static const _locationKey = 'profile_location';
  static const _bioKey = 'profile_bio';
  static const _facebookKey = 'profile_facebook';
  static const _instagramKey = 'profile_instagram';
  static const _linkedinKey = 'profile_linkedin';
  static const _githubKey = 'profile_github';
  static const _websiteKey = 'profile_website';

  static const defaultName = 'Explorer';
  static const defaultPhotoAsset = 'assets/profile/mahin_profile.jpg';

  String name = defaultName;
  String? photoPath;
  String profession = '';
  String gender = '';
  String bloodGroup = '';
  String company = '';
  String designation = '';
  String department = '';
  String phone = '';
  String email = '';
  String location = '';
  String bio = '';
  String facebook = '';
  String instagram = '';
  String linkedin = '';
  String github = '';
  String website = '';
  bool isLoading = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    name = prefs.getString(_nameKey) ?? defaultName;
    photoPath = prefs.getString(_photoPathKey);
    profession = prefs.getString(_professionKey) ?? '';
    gender = prefs.getString(_genderKey) ?? '';
    bloodGroup = prefs.getString(_bloodGroupKey) ?? '';
    company = prefs.getString(_companyKey) ?? '';
    designation = prefs.getString(_designationKey) ?? '';
    department = prefs.getString(_departmentKey) ?? '';
    phone = prefs.getString(_phoneKey) ?? '';
    email = prefs.getString(_emailKey) ?? '';
    location = prefs.getString(_locationKey) ?? '';
    bio = prefs.getString(_bioKey) ?? '';
    facebook = prefs.getString(_facebookKey) ?? '';
    instagram = prefs.getString(_instagramKey) ?? '';
    linkedin = prefs.getString(_linkedinKey) ?? '';
    github = prefs.getString(_githubKey) ?? '';
    website = prefs.getString(_websiteKey) ?? '';
    isLoading = false;
    notifyListeners();
  }

  ImageProvider get imageProvider {
    if (photoPath != null && File(photoPath!).existsSync()) {
      return FileImage(File(photoPath!));
    }
    return const AssetImage(defaultPhotoAsset);
  }

  Future<void> saveName(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    name = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    notifyListeners();
  }

  Future<void> saveDetails({
    required String name,
    required String profession,
    required String gender,
    required String bloodGroup,
    required String company,
    required String designation,
    required String department,
    required String phone,
    required String email,
    required String location,
    required String bio,
    required String facebook,
    required String instagram,
    required String linkedin,
    required String github,
    required String website,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) return;

    this.name = cleanedName;
    this.profession = profession.trim();
    this.gender = gender.trim();
    this.bloodGroup = bloodGroup.trim();
    this.company = company.trim();
    this.designation = designation.trim();
    this.department = department.trim();
    this.phone = phone.trim();
    this.email = email.trim();
    this.location = location.trim();
    this.bio = bio.trim();
    this.facebook = facebook.trim();
    this.instagram = instagram.trim();
    this.linkedin = linkedin.trim();
    this.github = github.trim();
    this.website = website.trim();

    final prefs = await SharedPreferences.getInstance();
    final values = <String, String>{
      _nameKey: this.name,
      _professionKey: this.profession,
      _genderKey: this.gender,
      _bloodGroupKey: this.bloodGroup,
      _companyKey: this.company,
      _designationKey: this.designation,
      _departmentKey: this.department,
      _phoneKey: this.phone,
      _emailKey: this.email,
      _locationKey: this.location,
      _bioKey: this.bio,
      _facebookKey: this.facebook,
      _instagramKey: this.instagram,
      _linkedinKey: this.linkedin,
      _githubKey: this.github,
      _websiteKey: this.website,
    };
    for (final entry in values.entries) {
      if (entry.value.isEmpty) {
        await prefs.remove(entry.key);
      } else {
        await prefs.setString(entry.key, entry.value);
      }
    }
    notifyListeners();
  }

  Future<bool> pickAndSavePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (picked == null) return false;

    final directory = await getApplicationDocumentsDirectory();
    final extension = picked.path.contains('.')
        ? picked.path.substring(picked.path.lastIndexOf('.'))
        : '.jpg';
    final destination = File('${directory.path}/profile_photo$extension');
    await File(picked.path).copy(destination.path);

    photoPath = destination.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoPathKey, photoPath!);
    notifyListeners();
    return true;
  }

  Future<void> resetProfile() async {
    name = defaultName;
    photoPath = null;
    profession = '';
    gender = '';
    bloodGroup = '';
    company = '';
    designation = '';
    department = '';
    phone = '';
    email = '';
    location = '';
    bio = '';
    facebook = '';
    instagram = '';
    linkedin = '';
    github = '';
    website = '';

    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _nameKey, _photoPathKey, _professionKey, _genderKey, _bloodGroupKey,
      _companyKey, _designationKey, _departmentKey, _phoneKey, _emailKey,
      _locationKey, _bioKey, _facebookKey, _instagramKey, _linkedinKey,
      _githubKey, _websiteKey,
    ]) {
      await prefs.remove(key);
    }
    notifyListeners();
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.radius = 26});

  final ProfileController profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profile.photoPath != null && File(profile.photoPath!).existsSync();
    if (hasPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: FileImage(File(profile.photoPath!)),
      );
    }

    // A neutral guest avatar is used until the user chooses a profile photo.
    return CircleAvatar(
      radius: radius,
      backgroundColor: CustomColors.primary.withOpacity(.12),
      child: Icon(Icons.person_rounded, size: radius * 1.05, color: CustomColors.primary),
    );
  }
}
