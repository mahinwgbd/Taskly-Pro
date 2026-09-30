import 'package:flutter/material.dart';

class CustomColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5548E8);
  static const Color accent = Color(0xFFFF4D9D);
  static const Color background = Color(0xFFF5F7FC);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF171B33);
  static const Color muted = Color(0xFF8B90A7);
  static const Color divider = Color(0xFFE9EBF2);
  static const Color green = Color(0xFF27C77B);
  static const Color yellow = Color(0xFFFFB82E);
  static const Color pink = Color(0xFFE83E9F);
  static const Color cyan = Color(0xFF22C7E8);
  static const Color orange = Color(0xFFFF8A3D);
  static const Color purple = Color(0xFF9B6BFF);

  // Kept for compatibility with the original project.
  static const Color GreyBackground = background;
  static const Color GreyBorder = divider;
  static const Color GreenLight = Color(0xFF63DFA3);
  static const Color GreenDark = green;
  static const Color GreenIcon = green;
  static const Color GreenAccent = green;
  static const Color GreenShadow = Color(0x3D27C77B);
  static const Color GreenBackground = Color(0x3027C77B);
  static const Color OrangeIcon = orange;
  static const Color OrangeBackground = Color(0x30FF8A3D);
  static const Color PurpleLight = Color(0xFFFF62C1);
  static const Color PurpleDark = pink;
  static const Color PurpleIcon = pink;
  static const Color PurpleAccent = pink;
  static const Color PurpleShadow = Color(0x45E83E9F);
  static const Color PurpleBackground = Color(0x30E83E9F);
  static const Color DeeppurlpleIcon = Color(0xFFBF0080);
  static const Color DeeppurlpleBackground = Color(0x30BF0080);
  static const Color BlueLight = Color(0xFF8EB8FF);
  static const Color BlueDark = primary;
  static const Color BlueIcon = cyan;
  static const Color BlueBackground = Color(0x3025B8D6);
  static const Color BlueShadow = Color(0x405B7CFA);
  static const Color HeaderBlueLight = Color(0xFF7BB5FF);
  static const Color HeaderBlueDark = primaryDark;
  static const Color HeaderGreyLight = Color(0x38FFFFFF);
  static const Color YellowIcon = yellow;
  static const Color YellowBell = yellow;
  static const Color YellowAccent = yellow;
  static const Color YellowShadow = Color(0x45FFB82E);
  static const Color YellowBackground = Color(0x30FFB82E);
  static const Color BellGrey = Color(0xFFD5D8E1);
  static const Color BellYellow = yellow;
  static const Color TrashRed = Color(0xFFF45151);
  static const Color TrashRedBackground = Color(0x30F45151);
  static const Color TextHeader = text;
  static const Color TextHeaderGrey = Color(0xFF656A80);
  static const Color TextSubHeaderGrey = muted;
  static const Color TextSubHeader = Color(0xFF737A98);
  static const Color TextBody = Color(0xFF70758C);
  static const Color TextGrey = Color(0xFFB1B5C3);
  static const Color TextWhite = Color(0xFFF8F9FC);
  static const Color HeaderCircle = Color(0x2DFFFFFF);
}

ThemeData appTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF0A0D18) : CustomColors.background,
    fontFamily: 'rubik',
    colorScheme: ColorScheme.fromSeed(
      seedColor: CustomColors.primary,
      brightness: brightness,
      surface: isDark ? const Color(0xFF141827) : Colors.white,
    ).copyWith(
      onSurface: isDark ? const Color(0xFFF4F6FF) : CustomColors.text,
      onSurfaceVariant: isDark ? const Color(0xFFB9C0D4) : CustomColors.muted,
      outline: isDark ? const Color(0xFF394154) : CustomColors.divider,
      outlineVariant: isDark ? const Color(0xFF2A3040) : CustomColors.divider,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: isDark ? const Color(0xFFF4F6FF) : CustomColors.text,
    ),
    cardColor: isDark ? const Color(0xFF141827) : Colors.white,
    cardTheme: CardThemeData(
      elevation: isDark ? 0 : 1.5,
      shadowColor: CustomColors.primary.withOpacity(isDark ? 0 : .08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerColor: isDark ? const Color(0xFF353C4F) : CustomColors.divider,
    iconTheme: IconThemeData(color: isDark ? const Color(0xFFDDE3F4) : CustomColors.text),
    switchTheme: SwitchThemeData(thumbColor: WidgetStatePropertyAll(isDark ? const Color(0xFFF4F6FF) : Colors.white), trackColor: WidgetStatePropertyAll(isDark ? CustomColors.primary.withOpacity(.55) : CustomColors.primary.withOpacity(.35)), trackOutlineColor: WidgetStatePropertyAll(isDark ? const Color(0xFF5A6580) : Colors.transparent)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF171B28) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CustomColors.primary, width: 1.5),
      ),
    ),
  );
}

// Lightweight app-wide localization. User-created content is never passed through this map.
String _tasklyLanguage = 'en';
void setTasklyLanguage(String languageCode) {
  _tasklyLanguage = languageCode == 'bn' ? 'bn' : 'en';
}

const Map<String, String> _bn = {
  'Active':'সক্রিয়','Archived':'আর্কাইভ','Trash':'ট্র্যাশ','Archive':'আর্কাইভ','Unarchive':'আনআর্কাইভ','Restore':'পুনরুদ্ধার','Delete permanently':'স্থায়ীভাবে মুছুন','Move to trash':'ট্র্যাশে সরান','Moved to trash':'ট্র্যাশে সরানো হয়েছে','Undo':'পূর্বাবস্থায়','Task deleted':'টাস্ক মুছে ফেলা হয়েছে','Task completed':'টাস্ক সম্পন্ন হয়েছে','Mark task complete':'টাস্ক সম্পন্ন হিসেবে চিহ্নিত করুন','Mark task incomplete':'টাস্ক অসম্পন্ন হিসেবে চিহ্নিত করুন',
  'Home':'হোম','Tasks':'টাস্ক','Notes':'নোট','Settings':'সেটিংস','Calendar':'ক্যালেন্ডার','Insights':'ইনসাইটস','Focus Mode':'ফোকাস মোড','Focus mode':'ফোকাস মোড',
  'Add task':'টাস্ক যোগ করুন','Add a new task':'নতুন টাস্ক যোগ করুন','Edit task':'টাস্ক সম্পাদনা','Task name':'টাস্কের নাম','Description (optional)':'বর্ণনা (ঐচ্ছিক)','What needs to be done?':'কী করতে হবে?','Add a little context...':'কিছু বিস্তারিত যোগ করুন...','Date':'তারিখ','Time':'সময়','Repeat':'পুনরাবৃত্তি','Reminder':'রিমাইন্ডার','On':'চালু','Off':'বন্ধ','Does not repeat':'পুনরাবৃত্তি নয়','Today':'আজ','Tomorrow':'আগামীকাল','Add a small step':'ছোট একটি ধাপ যোগ করুন','Subtasks':'সাবটাস্ক','Category':'ক্যাটাগরি','Priority':'অগ্রাধিকার','High':'উচ্চ','Medium':'মাঝারি','Low':'কম','Personal':'ব্যক্তিগত','Work':'কাজ','Meeting':'মিটিং','Study':'পড়াশোনা','Shopping':'কেনাকাটা','All':'সব','Overdue':'বকেয়া','High Priority':'উচ্চ অগ্রাধিকার','Hide done':'সম্পন্নগুলো লুকান','Sort by date':'তারিখ অনুযায়ী','Sort by priority':'অগ্রাধিকার অনুযায়ী','Recently added':'সাম্প্রতিক যোগ','Sort by title':'শিরোনাম অনুযায়ী',
  'Quick notes':'কুইক নোট','Quick Notes':'কুইক নোট','New note':'নতুন নোট','Edit note':'নোট সম্পাদনা','Save note':'নোট সংরক্ষণ','Capture a note':'একটি নোট লিখুন','Write something…':'কিছু লিখুন…','Write your first note':'আপনার প্রথম নোট লিখুন','Write':'লিখুন','Nothing here yet':'এখনও কিছু নেই','Ideas, meeting notes and checklists can live here.':'আইডিয়া, মিটিং নোট ও চেকলিস্ট এখানে রাখুন।','Checklist':'চেকলিস্ট','Color':'রং','Pin':'পিন','Pinned':'পিন করা','Unpin':'আনপিন','Delete':'মুছুন','Attachment':'অ্যাটাচমেন্ট','Draw':'আঁকুন','Insert drawing':'ড্রইং যোগ করুন','Emoji':'ইমোজি','Voice to text':'ভয়েস টু টেক্সট','Search':'সার্চ','Search tasks and notes...':'টাস্ক ও নোট খুঁজুন...','Search notes, tags and ideas...':'নোট, ট্যাগ ও আইডিয়া খুঁজুন...','Search workspace':'ওয়ার্কস্পেস সার্চ','Search your workspace':'আপনার ওয়ার্কস্পেস খুঁজুন','Nothing found':'কিছু পাওয়া যায়নি','Try a different keyword.':'অন্য কোনো শব্দ দিয়ে চেষ্টা করুন।','No notes found':'কোনো নোট পাওয়া যায়নি',
  'Your day':'আপনার দিন','Everything is under control.':'সবকিছু নিয়ন্ত্রণে আছে।','A clean slate. Make it yours.':'নতুন শুরু—নিজের মতো করে সাজান।','See all':'সব দেখুন','Focus spaces':'ফোকাস স্পেস','Jump into a category and keep moving.':'একটি ক্যাটাগরি বেছে নিয়ে এগিয়ে যান।','See your progress':'আপনার অগ্রগতি দেখুন','Your day is wide open':'আজকের দিনটি খালি','Add one small task and give today a direction.':'একটি ছোট টাস্ক যোগ করে আজকে অর্থবহ করুন।','Welcome to Taskly':'Taskly-তে স্বাগতম','Good morning':'শুভ সকাল','Good afternoon':'শুভ অপরাহ্ন','Good evening':'শুভ সন্ধ্যা','You did it!':'আপনি করে ফেলেছেন!','Start something great.':'দারুণ কিছু শুরু করুন।','Ready when you are.':'আপনি প্রস্তুত হলেই শুরু করুন।','done':'সম্পন্ন','left':'বাকি','notes':'নোট','tasks':'টাস্ক','in your workspace':'আপনার ওয়ার্কস্পেসে','task':'টাস্ক','note':'নোট','step':'ধাপ','steps':'ধাপ','checked':'সম্পন্ন',
  'Plan your days without losing the big picture.':'বড় ছবিটা না হারিয়ে দিন পরিকল্পনা করুন।','Nothing planned here':'এখানে কিছু পরিকল্পনা নেই','Keep the day light or add a task.':'দিনটা হালকা রাখুন অথবা একটি টাস্ক যোগ করুন।',
  'See how consistently you turn plans into progress.':'পরিকল্পনাকে কতটা নিয়মিত অগ্রগতিতে রূপ দিচ্ছেন দেখুন।','Completion':'সম্পন্নের হার','This week':'এই সপ্তাহ','Legend':'লেজেন্ড','Achiever':'অর্জনকারী',
  'Test notification sent':'টেস্ট নোটিফিকেশন পাঠানো হয়েছে','Send test notification':'টেস্ট নোটিফিকেশন পাঠান','Notification permission is not available.':'নোটিফিকেশন পারমিশন পাওয়া যাচ্ছে না.','Preferences':'পছন্দসমূহ','Notifications':'নোটিফিকেশন','Reminders are turned on':'রিমাইন্ডার চালু আছে','Reminders are turned off':'রিমাইন্ডার বন্ধ আছে','Appearance':'চেহারা','About Taskly':'Taskly সম্পর্কে','Developer':'ডেভেলপার','Dark theme is active':'ডার্ক থিম চালু আছে','Light theme is active':'লাইট থিম চালু আছে','Task reminders':'টাস্ক রিমাইন্ডার','Get a nudge when a task is due.':'টাস্কের সময় হলে মনে করিয়ে দিন।','Daily focus check-in':'দৈনিক ফোকাস চেক-ইন','A gentle reminder to review your day.':'দিনের কাজ পর্যালোচনার জন্য হালকা রিমাইন্ডার।','Done':'সম্পন্ন','Save':'সংরক্ষণ','Cancel':'বাতিল','Reset':'রিসেট','Reset profile':'প্রোফাইল রিসেট','My Profile':'আমার প্রোফাইল','Profile saved successfully.':'প্রোফাইল সফলভাবে সংরক্ষিত হয়েছে।','Profile photo updated.':'প্রোফাইল ছবি আপডেট হয়েছে।','Reset profile?':'প্রোফাইল রিসেট করবেন?','Not set':'সেট করা হয়নি','Personal information':'ব্যক্তিগত তথ্য','Professional':'পেশাগত','Social & web':'সামাজিক ও ওয়েব','Full name':'পূর্ণ নাম','Profession':'পেশা','Gender':'লিঙ্গ','Blood group':'রক্তের গ্রুপ','Address':'ঠিকানা','About me':'আমার সম্পর্কে','Company / Institution':'কোম্পানি / প্রতিষ্ঠান','Designation':'পদবি','Department':'বিভাগ','Phone':'ফোন','Mail':'ইমেইল','Personal website':'ব্যক্তিগত ওয়েবসাইট','Facebook':'Facebook','Instagram':'Instagram','LinkedIn':'LinkedIn','GitHub':'GitHub',
  'Backup & Restore':'ব্যাকআপ ও পুনরুদ্ধার','Export backup':'ব্যাকআপ এক্সপোর্ট','Restore backup':'ব্যাকআপ পুনরুদ্ধার','Save Taskly Backup':'Taskly ব্যাকআপ সংরক্ষণ','Select Taskly Backup':'Taskly ব্যাকআপ নির্বাচন','Keep your workspace safe':'আপনার ওয়ার্কস্পেস নিরাপদ রাখুন','Create a portable Taskly backup or restore one later on this device.':'Taskly-এর একটি বহনযোগ্য ব্যাকআপ তৈরি করুন বা পরে এই ডিভাইসে পুনরুদ্ধার করুন।','Save tasks, notes, profile, settings and profile photo as a JSON backup.':'টাস্ক, নোট, প্রোফাইল, সেটিংস ও প্রোফাইল ছবি JSON ব্যাকআপ হিসেবে সংরক্ষণ করুন।','Replace the current workspace with a previously exported Taskly backup.':'আগে এক্সপোর্ট করা Taskly ব্যাকআপ দিয়ে বর্তমান ওয়ার্কস্পেস প্রতিস্থাপন করুন।','Tip: keep a backup before changing phones or clearing app data.':'ফোন পরিবর্তন বা অ্যাপ ডেটা ক্লিয়ার করার আগে একটি ব্যাকআপ রাখুন।','Restore backup?':'ব্যাকআপ পুনরুদ্ধার করবেন?','Restoring replaces your current tasks, notes, profile and selected settings with the backup data. This cannot be undone.':'ব্যাকআপ পুনরুদ্ধার করলে বর্তমান টাস্ক, নোট, প্রোফাইল ও নির্বাচিত সেটিংস ব্যাকআপের ডেটা দিয়ে প্রতিস্থাপিত হবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।','Backup exported successfully.':'ব্যাকআপ সফলভাবে এক্সপোর্ট হয়েছে।','Could not export the backup.':'ব্যাকআপ এক্সপোর্ট করা যায়নি।','Backup restored successfully.':'ব্যাকআপ সফলভাবে পুনরুদ্ধার হয়েছে।','Could not restore the backup.':'ব্যাকআপ পুনরুদ্ধার করা যায়নি।',
  'Google Drive Backup':'Google Drive ব্যাকআপ','Google OAuth Setup':'Google OAuth সেটআপ','Connect Google Drive':'Google Drive সংযুক্ত করুন','Sync now':'এখন সিঙ্ক করুন','Disconnect':'সংযোগ বিচ্ছিন্ন','Web Client ID':'Web Client ID','Save & Restart Taskly':'সংরক্ষণ করে Taskly রিস্টার্ট','English':'English','বাংলা':'বাংলা','Created':'তৈরি','Title':'শিরোনাম','Updated':'আপডেট','Recent':'সাম্প্রতিক','Oldest':'পুরোনো','items':'টি','session':'সেশন','sessions':'সেশন','overdue':'বকেয়া','there':'আপনি','Choose a task below':'নিচের একটি টাস্ক বেছে নিন','Filter tasks...':'টাস্ক ফিল্টার করুন...','Find tasks, descriptions, categories and notes from one place.':'এক জায়গা থেকে টাস্ক, বর্ণনা, ক্যাটাগরি ও নোট খুঁজুন।','capture an idea':'একটি আইডিয়া লিখুন','Your ideas deserve a home':'আপনার আইডিয়ার জন্য একটি জায়গা দরকার','Try another keyword or turn off the pinned filter.':'অন্য শব্দ দিয়ে চেষ্টা করুন অথবা পিন ফিল্টার বন্ধ করুন।','Capture ideas, plans, meeting notes and checklists in one place.':'আইডিয়া, পরিকল্পনা, মিটিং নোট ও চেকলিস্ট এক জায়গায় রাখুন।','MON':'সোম','TUE':'মঙ্গল','WED':'বুধ','THU':'বৃহস্পতি','FRI':'শুক্র','SAT':'শনি','SUN':'রবি','JAN':'জানু','FEB':'ফেব্রু','MAR':'মার্চ','APR':'এপ্রিল','MAY':'মে','JUN':'জুন','JUL':'জুলাই','AUG':'আগস্ট','SEP':'সেপ্টে','OCT':'অক্টো','NOV':'নভে','DEC':'ডিসে','Monday':'সোমবার','Tuesday':'মঙ্গলবার','Wednesday':'বুধবার','Thursday':'বৃহস্পতিবার','Friday':'শুক্রবার','Saturday':'শনিবার','Sunday':'রবিবার',
  'Continue':'চালিয়ে যান','Skip':'এড়িয়ে যান','Let’s get started':'শুরু করা যাক','Getting started':'শুরু করছি','PLAN  •  FOCUS  •  FINISH':'পরিকল্পনা • ফোকাস • সম্পন্ন','PLAN WITHOUT THE NOISE':'অপ্রয়োজনীয়তা বাদ দিয়ে পরিকল্পনা করুন','CAPTURE EVERYTHING':'সবকিছু ধরে রাখুন','SEE YOUR MOMENTUM':'আপনার অগ্রগতি দেখুন',
  'Clean and bright':'পরিষ্কার ও উজ্জ্বল','Easy on the eyes at night':'রাতে চোখের জন্য আরামদায়ক','Follow your device':'ডিভাইসের সেটিং অনুসরণ করুন','System':'সিস্টেম','Light':'লাইট','Dark':'ডার্ক',
  'No matching tasks':'মিল পাওয়া যায়নি','Your task list is empty':'আপনার টাস্ক তালিকা খালি','Try another search or category.':'অন্য সার্চ বা ক্যাটাগরি চেষ্টা করুন।','Add something you want to get done.':'যে কাজটি করতে চান সেটি যোগ করুন।',
  'Tip':'টিপস','Pick one task, silence distractions, and work until the timer ends. Short breaks between sessions keep your focus sustainable.':'একটি টাস্ক বেছে নিন, মনোযোগ নষ্ট করে এমন বিষয় বন্ধ করুন এবং টাইমার শেষ হওয়া পর্যন্ত কাজ করুন। সেশনের মাঝে ছোট বিরতি নিন।','Focus task':'ফোকাস টাস্ক','Add an unfinished task to start a focus session.':'ফোকাস সেশন শুরু করতে একটি অসম্পন্ন টাস্ক যোগ করুন।','PAUSE':'বিরতি','DONE':'সম্পন্ন','DEEP WORK':'গভীর মনোযোগ',
  'Could not sync with Google Drive.':'Google Drive-এর সাথে সিঙ্ক করা যায়নি।','Voice input is not available on this device.':'এই ডিভাইসে ভয়েস ইনপুট পাওয়া যাচ্ছে না।','Could not attach the selected file.':'নির্বাচিত ফাইল সংযুক্ত করা যায়নি।','Could not save drawing.':'ড্রইং সংরক্ষণ করা যায়নি।','This file provider did not return a local path.':'ফাইল প্রোভাইডার কোনো লোকাল পাথ দেয়নি।',
};


const Map<String, String> _bnExtra = {
  'to go':'যেতে হবে',
  'Explorer':'এক্সপ্লোরার',
  'Guest':'অতিথি',
  'OVERDUE':'বকেয়া',
  'A calm little workspace for tasks, notes, projects, and everyday progress.\n\nVersion 4.1.0\nMade to help you focus on what matters next.':'টাস্ক, নোট, প্রজেক্ট ও দৈনন্দিন অগ্রগতির জন্য একটি শান্ত ও সহজ ওয়ার্কস্পেস।\n\nভার্সন ৪.০.০\nযা গুরুত্বপূর্ণ তাতে মনোযোগ ধরে রাখতে তৈরি।',
  'waiting for you.':'আপনার জন্য অপেক্ষা করছে।',
  'in your space.':'আপনার স্পেসে আছে।',
  'Plan your days':'আপনার দিন পরিকল্পনা করুন',
  'Untitled note':'শিরোনামহীন নোট',
  'Just now':'এইমাত্র',
  'm ago':'মিনিট আগে',
  'h ago':'ঘণ্টা আগে',
  'd ago':'দিন আগে',
  'Give this idea a name':'এই আইডিয়ার একটি নাম দিন',
  'Write your thoughts, meeting notes, plans...':'আপনার ভাবনা, মিটিং নোট ও পরিকল্পনা লিখুন...',
  'Tags':'ট্যাগ',
  'work, idea, personal':'কাজ, আইডিয়া, ব্যক্তিগত',
  'Add checklist item':'চেকলিস্ট আইটেম যোগ করুন',
  'Save changes':'পরিবর্তন সংরক্ষণ',
  'Create task':'টাস্ক তৈরি করুন','All tags':'সব ট্যাগ','New task':'নতুন টাস্ক',
  'Refine the details and keep moving.':'বিস্তারিত ঠিক করে এগিয়ে যান।',
  'Turn your next action into progress.':'পরবর্তী কাজটিকে অগ্রগতিতে পরিণত করুন।',
  'Ideas, reminders, or anything worth keeping.':'আইডিয়া, রিমাইন্ডার বা সংরক্ষণ করার মতো যেকোনো কিছু।',
  'Daily':'প্রতিদিন','Weekdays':'কর্মদিবস','Weekends':'সাপ্তাহিক ছুটি',
  'Weekly':'সাপ্তাহিক',
  'Monthly':'মাসিক',
  'Completion':'সম্পন্নের হার',
  'Pending':'অমীমাংসিত',
  'Overdue':'বকেয়া',
  'High priority':'উচ্চ অগ্রাধিকার',
  'day streak':'দিনের ধারাবাহিকতা',
  'Complete a task today to start.':'শুরু করতে আজ একটি টাস্ক সম্পন্ন করুন।',
  'Keep the chain alive.':'ধারাবাহিকতা ধরে রাখুন।',
  'completed task':'টি টাস্ক সম্পন্ন',
  'completed tasks':'টি টাস্ক সম্পন্ন',
  'Categories':'ক্যাটাগরি',
  'Version 4.1.0 • Built for focus':'ভার্সন ৪.১.০ • ফোকাসের জন্য তৈরি',
  'The basics people use to know you.':'আপনার পরিচয়ের মৌলিক তথ্যগুলো।',
  'Make your work or study identity visible.':'আপনার কাজ বা পড়াশোনার পরিচয় তুলে ধরুন।',
  'Contact':'যোগাযোগ',
  'Keep your important contact details together.':'গুরুত্বপূর্ণ যোগাযোগের তথ্য এক জায়গায় রাখুন।',
  'Add the places where people can find you.':'যেসব জায়গায় মানুষ আপনাকে খুঁজে পাবে সেগুলো যোগ করুন।',
  'Saving profile...':'প্রোফাইল সংরক্ষণ হচ্ছে...',
  'Save profile':'প্রোফাইল সংরক্ষণ',
  'Private & synced by your choice':'আপনার পছন্দ অনুযায়ী ব্যক্তিগত ও সিঙ্ক করা',
  'Your profile stays local unless you connect Google Drive backup in Settings.':'Settings থেকে Google Drive ব্যাকআপ সংযুক্ত না করা পর্যন্ত আপনার প্রোফাইল ডিভাইসেই থাকবে।',
  'Your personal, professional, contact, and social details will be cleared and the default Taskly profile will be restored.':'আপনার ব্যক্তিগত, পেশাগত, যোগাযোগ ও সামাজিক তথ্য মুছে গিয়ে ডিফল্ট Taskly প্রোফাইল পুনরুদ্ধার হবে।',
  'Default profile restored.':'ডিফল্ট প্রোফাইল পুনরুদ্ধার হয়েছে।',
  'Add your personal & work details':'আপনার ব্যক্তিগত ও কাজের তথ্য যোগ করুন',
  'IT Enthusiasts':'আইটি উৎসাহীরা',
  'Choose how Taskly should look.':'Taskly কেমন দেখাবে তা বেছে নিন।',
  'Paste the Web application OAuth client ID from Google Cloud Console. This is not a password. Android also needs an OAuth client matching Taskly’s package name and SHA-1.':'Google Cloud Console থেকে Web application OAuth client ID দিন। এটি কোনো পাসওয়ার্ড নয়। Android-এর জন্য Taskly-এর package name ও SHA-1-এর সঙ্গে মিলে এমন OAuth client-ও প্রয়োজন।',
  'Enter a valid Web Client ID ending in .apps.googleusercontent.com':'সঠিক Web Client ID দিন, যা .apps.googleusercontent.com দিয়ে শেষ হবে।',
  'Google Client ID saved. Restart Taskly, then connect Google Drive.':'Google Client ID সংরক্ষিত হয়েছে। Taskly রিস্টার্ট করে Google Drive সংযুক্ত করুন।',
  'Keep your Taskly data safe in your Google Drive.':'আপনার Taskly-এর ডেটা Google Drive-এ নিরাপদ রাখুন।',
  'Synced with':'সিঙ্ক হয়েছে',
  'Connecting...':'সংযুক্ত হচ্ছে...',
  'Your backup stays in Drive even if Taskly is uninstalled.':'Taskly আনইনস্টল হলেও আপনার ব্যাকআপ Drive-এ থাকবে।',
  'No pressure. Start with one small win.':'চাপ নেই। একটি ছোট কাজ দিয়ে শুরু করুন।',
  'Perfect finish. Protect this momentum.':'দারুণ সমাপ্তি। এই গতি ধরে রাখুন।',
  'Almost there. One last push can close the loop.':'প্রায় শেষ। আরেকটু চেষ্টা করলেই কাজ সম্পূর্ণ হবে।',
  'You are in the flow. Keep the rhythm going.':'আপনি কাজের ছন্দে আছেন। ছন্দ ধরে রাখুন।',
  'Solid progress. Your future self will thank you.':'ভালো অগ্রগতি। ভবিষ্যতের আপনি এর জন্য কৃতজ্ঞ থাকবেন।',
  'Good start. Small wins are adding up.':'ভালো শুরু। ছোট ছোট সাফল্য জমা হচ্ছে।',
  'One step is enough to start the momentum.':'গতি শুরু করতে একটি ধাপই যথেষ্ট।',
  'Pick one thing. Give it your full attention.':'একটি কাজ বেছে নিন। পুরো মনোযোগ দিন।',
  'PLAN WITHOUT THE NOISE':'অপ্রয়োজনীয়তা বাদ দিয়ে পরিকল্পনা করুন',
  'CAPTURE EVERYTHING':'সবকিছু ধরে রাখুন',
  'SEE YOUR MOMENTUM':'আপনার অগ্রগতি দেখুন',
  'Turn busy days\ninto clear steps.':'ব্যস্ত দিনকে\nপরিষ্কার ধাপে সাজান।',
  'Tasks, focus sessions and progress—designed to keep your attention on what matters.':'টাস্ক, ফোকাস সেশন ও অগ্রগতি—যা গুরুত্বপূর্ণ তাতে মনোযোগ ধরে রাখার জন্য তৈরি।',
  'Ideas deserve\na place too.':'আইডিয়ারও\nএকটি জায়গা দরকার।',
  'Write notes, add checklists, pin important thoughts and find them instantly.':'নোট লিখুন, চেকলিস্ট যোগ করুন, গুরুত্বপূর্ণ ভাবনা পিন করুন এবং মুহূর্তেই খুঁজে নিন।',
  'Small wins become\nbig progress.':'ছোট সাফল্যই\বড় অগ্রগতি তৈরি করে।',
  'Track completion, build streaks and understand how your time is moving.':'কাজের অগ্রগতি দেখুন, ধারাবাহিকতা তৈরি করুন এবং সময় কীভাবে কাটছে বুঝুন।',
  'Getting started':'শুরু করছি',
  'Continue':'চালিয়ে যান',
  'Skip':'এড়িয়ে যান',
  'Let’s get started':'শুরু করা যাক',
  'DONE':'সম্পন্ন',
  'TODAY':'আজ',
  'Filter tasks...':'টাস্ক ফিল্টার করুন...',
  'My Tasks':'আমার টাস্ক',
  'Stay on top of the things that matter.':'গুরুত্বপূর্ণ কাজগুলোর ওপর নজর রাখুন।',
  'YOUR PROFILE':'আপনার প্রোফাইল',
  'Meet the developer':'ডেভেলপারের সাথে পরিচিত হন',
  'Profile':'প্রোফাইল',
  'Connect Google Drive':'Google Drive সংযুক্ত করুন',
  'Layout':'লেআউট',
  'Pinned only':'শুধু পিন করা',
  'Edit':'সম্পাদনা',
  'Items':'টি',
  'items':'টি',
  'Choose a task below':'নিচের একটি টাস্ক বেছে নিন',
  'in your workspace':'আপনার ওয়ার্কস্পেসে',
  'overdue':'বকেয়া',
  'there':'আপনি',
  'session':'সেশন',
  'sessions':'সেশন',
  'Date':'তারিখ',
  'Priority':'অগ্রাধিকার',
  'Created':'তৈরি',
  'Title':'শিরোনাম',
  'Updated':'আপডেট',
  'Recent':'সাম্প্রতিক',
  'Oldest':'পুরোনো',
  'Find tasks, descriptions, categories and notes from one place.':'এক জায়গা থেকে টাস্ক, বর্ণনা, ক্যাটাগরি ও নোট খুঁজুন।',
  'capture an idea':'একটি আইডিয়া লিখুন',
  'Your ideas deserve a home':'আপনার আইডিয়ার জন্য একটি জায়গা দরকার',
  'Try another keyword or turn off the pinned filter.':'অন্য শব্দ দিয়ে চেষ্টা করুন অথবা পিন ফিল্টার বন্ধ করুন।',
  'Capture ideas, plans, meeting notes and checklists in one place.':'আইডিয়া, পরিকল্পনা, মিটিং নোট ও চেকলিস্ট এক জায়গায় রাখুন।',
  'MON':'সোম',
  'TUE':'মঙ্গল',
  'WED':'বুধ',
  'THU':'বৃহস্পতি',
  'FRI':'শুক্র',
  'SAT':'শনি',
  'SUN':'রবি',
  'JAN':'জানু',
  'FEB':'ফেব্রু',
  'MAR':'মার্চ',
  'APR':'এপ্রিল',
  'MAY':'মে',
  'JUN':'জুন',
  'JUL':'জুলাই',
  'AUG':'আগস্ট',
  'SEP':'সেপ্টে',
  'OCT':'অক্টো',
  'NOV':'নভে',
  'DEC':'ডিসে',
  'Monday':'সোমবার',
  'Tuesday':'মঙ্গলবার',
  'Wednesday':'বুধবার',
  'Thursday':'বৃহস্পতিবার',
  'Friday':'শুক্রবার',
  'Saturday':'শনিবার',
  'Sunday':'রবিবার',
  'Google OAuth is not configured yet. Add your Web Client ID in Settings → Google Drive Backup → Google OAuth Setup.':'Google OAuth এখনো কনফিগার করা হয়নি। Settings → Google Drive Backup → Google OAuth Setup-এ Web Client ID দিন।',
  'Invalid Web Client ID. It should end with .apps.googleusercontent.com.':'অবৈধ Web Client ID। এটি .apps.googleusercontent.com দিয়ে শেষ হতে হবে।',
  'Google OAuth needs your Web Client ID. Add it in Settings → Google Drive Backup → Google OAuth Setup, then restart Taskly.':'Google OAuth-এর জন্য Web Client ID প্রয়োজন। Settings → Google Drive Backup → Google OAuth Setup-এ এটি দিন, তারপর Taskly রিস্টার্ট করুন।',
  'Google OAuth configuration error (DEVELOPER_ERROR). Google Cloud must have an Android OAuth client for package com.taskly.app + your debug SHA-1, and the Web Client ID must be the serverClientId.':'Google OAuth কনফিগারেশন সমস্যা (DEVELOPER_ERROR)। com.taskly.app + debug SHA-1-এর Android OAuth client এবং সঠিক Web Client ID প্রয়োজন।',
  'Google sign-in was cancelled or Android could not match the configured OAuth client.':'Google sign-in বাতিল হয়েছে অথবা Android কনফিগার করা OAuth client খুঁজে পায়নি।',
  'Google sign-in failed. Check your OAuth client and SHA-1 configuration.':'Google sign-in ব্যর্থ হয়েছে। OAuth client ও SHA-1 configuration পরীক্ষা করুন।',
  'Your day is wide open':'আজকের দিনটি খালি',
  'You did it!':'আপনি করে ফেলেছেন!',
  'Start something great.':'দারুণ কিছু শুরু করুন।',
  'step':'ধাপ',
  'steps':'ধাপ',
  'Waiting for you':'আপনার জন্য অপেক্ষা করছে',
  'See all':'সব দেখুন',
  'Save an idea before it disappears.':'আইডিয়াটি হারিয়ে যাওয়ার আগে সংরক্ষণ করুন।',
  'note':'নোট',
  'notes':'নোট',
  'min ago':'মিনিট আগে',
  'hour ago':'ঘণ্টা আগে',
  'day ago':'দিন আগে',
  'Please enter your name':'আপনার নাম লিখুন',
  'e.g. Software Engineer':'যেমন: সফটওয়্যার ইঞ্জিনিয়ার',
  'City / Country':'শহর / দেশ',
  'A short line about yourself':'নিজের সম্পর্কে সংক্ষিপ্ত কিছু লিখুন',
  'Where you work or study':'যেখানে কাজ করেন বা পড়াশোনা করেন',
  'e.g. Senior Engineer':'যেমন: সিনিয়র ইঞ্জিনিয়ার',
  'Optional':'ঐচ্ছিক',
  'Profile link or username':'প্রোফাইল লিংক বা ইউজারনেম',
  'Your workspace is personal. Shape it around the way you work and live.':'আপনার ওয়ার্কস্পেস ব্যক্তিগত। আপনার কাজ ও জীবনযাপনের ধরন অনুযায়ী সাজান।',
  'Google OAuth Setup':'Google OAuth সেটআপ',
  'Add note':'নোট যোগ করুন',
  'Blood group':'রক্তের গ্রুপ',
};
String tr(String key) => _tasklyLanguage == 'bn' ? (_bn[key] ?? _bnExtra[key] ?? key) : key;

/// Formats numeric UI values using Bengali digits when Bangla is selected.
/// User-entered task/note/profile content is never altered by this helper.
String localizeNumber(num value, {int? fractionDigits}) {
  final raw = fractionDigits == null
      ? value.toString()
      : value.toStringAsFixed(fractionDigits);
  return localizeDigits(raw);
}

String localizeDigits(String value) {
  if (_tasklyLanguage != 'bn') return value;
  const western = '0123456789';
  const bengali = '০১২৩৪৫৬৭৮৯';
  return value.split('').map((c) {
    final i = western.indexOf(c);
    return i >= 0 ? bengali[i] : c;
  }).join();
}

String localizeCount(int value) => localizeNumber(value);
