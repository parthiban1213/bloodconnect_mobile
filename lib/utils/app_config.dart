// ─────────────────────────────────────────────────────────────
//  AppConfig  —  single place to update all configurable
//               texts, labels, and asset references.
//  Change a value here; it propagates everywhere in the app.
// ─────────────────────────────────────────────────────────────

class AppConfig {
  // ── Support ─────────────────────────────────────────────────
  static const String supportUrl   = 'https://www.hsblood.in/support';
  static const String supportLabel = 'Get Support';

  // ── Branding ────────────────────────────────────────────────
  static const String appName          = 'BloodConnect';
  static const String orgName          = 'HSBlood';
  static const String appVersion       = '1.0';
  static const String footerText       = '$appName · $orgName v$appVersion';

  // ── Splash ──────────────────────────────────────────────────
  static const String splashBrandBold  = 'HS';
  static const String splashBrandLight = 'Blood';
  static const String splashTagline    = 'Every drop counts.';

  // ── Login — OTP screen ──────────────────────────────────────
  static const String otpEyebrow       = 'Blood Donor Registry';
  static const String otpHeading       = 'Welcome\nback';
  static const String otpSubtext       = 'Sign in with your registered mobile\nnumber to see blood requests near you.';
  static const String otpContinueBtn   = 'Continue with OTP →';
  static const String otpSwitchBtn     = 'Sign in with Username & Password';
  static const String otpRegisterBtn   = 'Register';
  static const String otpHintTitle     = 'Need any help?';
  static const String otpHintBody      = 'Contact your $orgName administrator. All accounts are managed centrally.';
  static const String otpCountryFlag   = '🇮🇳';
  static const String otpCountryCode   = '+91';
  static const String otpPlaceholder   = '98765 43210';
  static const int    otpTimerSeconds  = 60;

  // ── OTP Code screen ─────────────────────────────────────────
  static const String otpCodeTitle     = 'Enter OTP';
  static const String otpCodeSentTo    = 'Sent to ';
  static const String otpChangeNumber  = 'Change number';
  static const String otpResendTimer   = 'Resend OTP in ';
  static const String otpResendBtn     = 'Resend OTP';
  static const String otpVerifyBtn     = 'Verify & Sign In →';

  // ── Login — Password screen ──────────────────────────────────
  static const String pwdHeading              = 'Welcome\nback';
  static const String pwdSubtext              = 'Sign in to see blood requests\nnear you and save lives.';
  static const String pwdSignInBtn            = 'Sign in →';
  static const String pwdSwitchBtn            = 'Sign in with OTP instead';
  static const String pwdHintTitle            = 'Need access?';
  static const String pwdHintBody             = 'Contact your administrator for login credentials. All accounts are managed by $orgName admin.';
  static const String pwdUsernamePlaceholder  = 'Enter username';
  static const String pwdPasswordPlaceholder  = 'Enter password';
  static const String pwdForgotLink           = 'Forgot password?';
  static const String pwdBackLink             = 'Back';
  static const String pwdSignInLabel          = 'Sign in →';

  // ── Login — Forgot Password screen ──────────────────────────
  static const String fpTitle                = 'Reset Password';
  static const String fpBackLink             = 'Back to Sign In';
  static const String fpResetBtn             = 'Reset Password →';
  static const String fpHintTitle            = 'Need help?';
  static const String fpHintBody             = 'Make sure the email matches the one registered with your $orgName account. Contact your administrator if you have forgotten your username.';
  static const String fpSuccessMsg           = 'Password reset successful! You can now sign in with your new password.';
  static const String fpUsernamePlaceholder  = 'Your username';
  static const String fpEmailPlaceholder     = 'Email linked to your account';
  static const String fpNewPwdPlaceholder    = 'Min. 6 characters';
  static const String fpConfirmPlaceholder   = 'Re-enter new password';

  // ── Session expired ──────────────────────────────────────────
  static const String sessionExpiredTitle = 'Session expired';
  static const String sessionExpiredBody  = 'Please sign in again to continue.';

  // ── Register screen ──────────────────────────────────────────
  // Step 1 — Mobile entry
  static const String regBrandSub          = 'Donor Registry';
  static const String regHeading           = 'Create your account';
  static const String regSubtext           = 'Register as an $orgName donor';
  static const String regHintBody          = 'Enter your mobile number. We\'ll send you a one-time passcode to verify your identity.';
  static const String regSendOtpBtn        = 'Send OTP';
  static const String regSignInDivider     = 'Already have an account?';
  static const String regSignInBtn         = 'Sign in';

  // Step 2 — OTP verification
  static const String regOtpIconTitle      = 'Check your SMS';
  static const String regOtpSentPrefix     = 'Code sent to +91 ';
  static const String regOtpChangeNumber   = 'Change number';
  static const String regOtpHeading        = 'Enter verification code';
  static const String regOtpSubtext        = 'Enter the 6-digit OTP sent to your mobile.';
  static const String regVerifyBtn         = 'Verify OTP';
  static const String regResendBtn         = 'Resend OTP';
  static const String regResendTimerPrefix = 'Resend code in ';
  static const String regResendTimerSuffix = 's';

  // Step 3 — Details form
  static const String regVerifiedSuffix    = ' verified';
  static const String regDetailsHeading    = 'Complete your profile';
  static const String regDetailsSubtitle   = 'New $orgName registration';
  static const String regSectionPersonal   = 'Personal Information';
  static const String regSectionDonor      = '🩸 Donor Information';
  static const String regSectionContact    = 'Contact Details';
  static const String regSectionOptional   = 'Additional Details (optional)';
  static const String regFirstNameLabel    = 'First Name *';
  static const String regLastNameLabel             = 'Last Name *';
  static const String regLastNameOptionalLabel     = 'Last Name (optional)';
  static const String regFirstNameHint     = 'e.g. Arjun';
  static const String regLastNameHint      = 'e.g. Kumar';
  static const String regBloodTypeLabel    = 'Blood Type *';
  static const String regBloodTypeHint     = 'Select blood type';
  static const String regUsernameLabel     = 'Username *';
  static const String regUsernameHint      = 'e.g. arjun_kumar';
  static const String regEmailLabel            = 'Email Address *';
  static const String regEmailOptionalLabel    = 'Email Address (optional)';
  static const String regUsernameAutoNote      = 'Your login username will be generated automatically from your name.';
  static const String regEmailHint         = 'you@example.com';
  static const String regAddressLabel      = 'Address (optional)';
  static const String regAddressHint       = 'Street, City, State';
  static const String regLastDonationLabel = 'Last Donation Date';
  static const String regLastDonationHint  = 'Select date';
  static const String regAvailabilityLabel = 'Availability Status';
  static const String regAvailableOption   = '✅  Available';
  static const String regUnavailableOption = '❌  Not Available';
  static const String regSubmitBtn         = 'Complete Registration ✨';
  static const String regBackBtn           = 'Back';

  // Validation messages
  static const String regErrFirstLast      = 'First name and last name are required.';
  static const String regErrFirstName     = 'Please enter your first name.';
  static const String regErrBloodType      = 'Please select your blood type.';
  static const String regErrUsername       = 'Username must be at least 3 characters.';
  static const String regErrEmail          = 'Please enter a valid email address.';
  static const String regErrEmailRequired  = 'Email address is required.';
  static const String regErrOtpSend        = 'Failed to send OTP. Please try again.';
  static const String regErrMobileEmpty    = 'Please enter your mobile number.';
  static const String regErrMobileInvalid  = 'Enter a valid 10-digit Indian mobile number.';

  // ── Feed screen ──────────────────────────────────────────────
  static const String feedSearchHint   = 'Search hospital or blood type…';
  static const String feedFilterTitle  = 'Filter Requests';
  static const String feedOpenRequests = 'open blood requests';

  // Feed filter chips
  static const List<Map<String, String>> feedFilters = [
    {'label': 'All',        'key': 'All'},
    {'label': 'Critical',   'key': 'Critical'},
    {'label': 'High',       'key': 'High'},
    {'label': 'Medium',     'key': 'Medium'},
    {'label': 'Low',        'key': 'Low'},
    {'label': 'Open',       'key': 'Open'},
    {'label': 'Fulfilled',  'key': 'Fulfilled'},
    {'label': 'Cancelled',  'key': 'Cancelled'},
  ];

  // ── Requirement card (feed) ──────────────────────────────────
  static const String cardNotEligibleBtn   = 'Not Eligible';
  static const String cardDonateBtn       = "I'll Donate";
  static const String cardCantHelpBtn     = "Can't help";
  static const String cardNotMyTypeBtn    = 'Not my type';
  static const String cardAlreadyDonated  = 'Already Donated';
  static const String cardDeclineBtn      = 'Decline';
  static const String cardConfirmDonation = 'Confirm donation';
  static const String cardBackToFeed      = 'Back to feed';

  // ── Accepted screen ──────────────────────────────────────────
  static const String acceptedTitle       = "You're confirmed!";
  static const String acceptedSubtitle    = 'Hospital has been notified. Thank you.';
  static const String acceptedDonatingAt  = 'Donating at';
  static const String acceptedContactLabel = 'CONTACT';
  static const String acceptedCallBtn     = 'Call';
  static const String acceptedBackBtn     = 'Back to Feed';
  static const String acceptedWhatToBring = 'What to bring';
  static const List<String> acceptedBringItems = [
    'Eat a light meal before donating',
    'Stay hydrated — drink water now',
  ];

  // ── Requirement detail screen ────────────────────────────────
  static const String detailHospitalContact = 'HOSPITAL CONTACT';
  static const String detailRequiredBy      = 'Required by: ';
  static const String detailAlreadyDonated  = 'Already Donated';
  static const String detailScheduledPending = 'Scheduled — awaiting approval';

  // ── Directory screen ─────────────────────────────────────────
  static const String directoryTitle       = 'Directory';
  static const String directorySearchHint  = 'Search hospitals, blood banks…';
  static const String directoryEmptyTitle  = 'No entries found';
  static const String directoryEmptyBody   = 'No hospitals or services match your search.';
  static const List<Map<String, String>> directoryCategories = [
    {'label': 'All',         'key': 'All'},
    {'label': 'Hospitals',   'key': 'Hospital'},
    {'label': 'Blood Banks', 'key': 'Blood Bank'},
    {'label': 'Ambulance',   'key': 'Ambulance'},
  ];

  // ── Donors screen ────────────────────────────────────────────
  static const String donorsTitle              = 'Donors';
  static const String donorsSearchHint         = 'Search by name, phone, address…';
  static const String donorsEmptyTitle         = 'No donors found';
  static const String donorsEmptySubtitle      = 'Try adjusting your search or filters.';
  static const String donorsFilterTitle        = 'Filter Donors';
  static const String donorsFilterBloodType    = 'Blood Type';
  static const String donorsFilterAvailability = 'Availability';
  static const String donorsFilterAvailable    = 'Available';
  static const String donorsFilterUnavailable  = 'Unavailable';
  static const String donorsFilterApply        = 'Apply';
  static const String donorsFilterClear        = 'Clear';
  static const String donorDetailTitle         = 'Donor Details';

  // ── History screen ───────────────────────────────────────────
  static const String historyMyDonations          = 'My Donations';
  static const String historyCompleted            = 'Completed';
  static const String historyNoDonations          = 'No donations yet';
  static const String historyNoDonationsSubtitle  =
      'When you pledge to donate blood, your donations will appear here.';
  static const String historyNoCompleted          = 'No completed requests';
  static const String historyNoCompletedSubtitle  =
      'Your fulfilled and cancelled blood requests will appear here.';
  static const String historyDonatedBadge         = 'Donated';

  // ── My Requests screen ───────────────────────────────────────
  static const String myRequestsAddBtn        = 'Add Request';
  static const String myRequestsEmptyTitle    = 'No requests yet';
  static const String myRequestsEmptySubtitle =
      'Tap "Add Request" above to create your first blood requirement.';
  static const String myRequestsViewStatus    = 'View Status';
  static const String myRequestsEdit          = 'Edit';
  static const String myRequestsClose         = 'Close';
  static const String myRequestsCloseTitle    = 'Close Request';
  static const String myRequestsCloseBody     =
      'Are you sure you want to close this request? It will be marked as Cancelled.';
  static const String myRequestsCloseCancel   = 'Cancel';
  static const String myRequestsCloseConfirm  = 'Close Request';
  static const String myRequestsCloseError    = 'Failed to close request.';

  // ── Add/Edit Requirement screen ──────────────────────────────
  static const String addReqTitleNew        = 'New Blood Request';
  static const String addReqTitleEdit       = 'Edit Blood Request';
  static const String addReqSaveBtn         = 'Save Requirement';
  static const String addReqSectionPatient  = 'Patient Details';
  static const String addReqSectionContact  = 'Contact Information';
  static const String addReqSectionDetails  = 'Requirement Details';
  static const String addReqPatientName     = 'Patient Name';
  static const String addReqHospital        = 'Hospital / Centre';
  static const String addReqLocation        = 'Location';
  static const String addReqContactPerson   = 'Contact Person';
  static const String addReqContactPhone    = 'Contact Phone';
  static const String addReqBloodType       = 'Blood Type';
  static const String addReqUnits           = 'Units Required';
  static const String addReqUrgency         = 'Urgency';
  static const String addReqRequiredBy      = 'Required By Date';
  static const String addReqStatus          = 'Status';
  static const String addReqNotes           = 'Additional Notes';
  static const String addReqPatientHint     = 'e.g. Ravi Kumar';
  static const String addReqHospitalHint    = 'e.g. PSG Hospital';
  static const String addReqLocationHint    = 'e.g. Coimbatore, Tamil Nadu';
  static const String addReqContactHint     = 'Name of coordinator';
  static const String addReqPhoneHint       = '+91 98765 43210';
  static const String addReqBloodTypeHint   = 'Select blood type';
  static const String addReqDateHint        = 'Select date (optional)';
  static const String addReqNotesHint       = 'Any special instructions or context…';
  static const String addReqCreatedMsg      = 'Requirement created successfully!';
  static const String addReqUpdatedMsg      = 'Request updated successfully!';

  // ── Notifications screen ─────────────────────────────────────
  static const String notifTitle         = 'Notifications';
  static const String notifSubtitle      = 'Blood alerts';
  static const String notifMarkAllRead   = 'Mark all read';
  static const String notifUnreadSuffix  = ' unread';
  static const String notifEmptyTitle    = 'No notifications yet';
  static const String notifEmptySubtitle = "You'll be notified when blood requests match your type.";

  // ── Profile screen ───────────────────────────────────────────
  static const String profileDonationLabel   = 'Units\nDonated';
  static const String profileAvailableLabel  = 'Available to donate';
  static const String profileAvailableOn     = 'You will receive blood requests';
  static const String profileAvailableOff    = 'You are not available right now';
  static const String profileEditProfile     = 'Edit Profile';
  static const String profileBloodType       = 'Blood Type';
  static const String profileChangePassword  = 'Change Password';
  static const String profileAccountRole     = 'Account Role';
  static const String profileLastDonation    = 'Last donation: ';
  static const String profileNextEligible    = 'Next Eligible Date';
  static const String profileDaysUntil       = 'Days until next donation';
  static const String profileSignOut         = 'Sign Out';
  static const String profileSignOutTitle    = 'Sign out';
  static const String profileSignOutBody     = 'Are you sure you want to sign out?';
  static const String profileSignOutCancel   = 'Cancel';
  static const String profileSignOutConfirm  = 'Sign out';
  static const String profileDeleteAccount   = 'Delete Account?';
  static const String profileDeleteAccountTitle    = 'Delete Account';
  static const String profileDeleteAccountBody     = 'Are you sure you want to Delete?';
  static const String profileDeleteAccountCancel   = 'Cancel';
  static const String profileDeleteAccountConfirm  = 'Delete';
  static const String profileChangePwdTitle  = 'Change Password';
  static const String profileNewPwdLabel     = 'New password';
  static const String profileConfirmPwdLabel = 'Confirm new password';
  static const String profilePwdChanged      = 'Password changed!';
  static const String profilePwdChangeFailed = 'Failed to change password.';
  static const String profileThankYou        = 'Thank you!';
  static const String profileNotSet          = 'Not set';

  // ── Edit Profile screen ──────────────────────────────────────
  static const String editProfileTitle      = 'Edit Profile';
  static const String editProfileSaveBtn    = 'Save Changes';
  static const String editProfileFirstName  = 'First name';
  static const String editProfileLastName   = 'Last name';
  static const String editProfileEmail      = 'Email';
  static const String editProfileMobile     = 'Mobile';
  static const String editProfileAddress    = 'Address';
  static const String editProfileBloodType  = 'BLOOD TYPE';
  static const String editProfileSuccess    = 'Profile updated!';
  static const String editProfileFirstHint  = 'Enter first name';
  static const String editProfileLastHint   = 'Enter last name';
  static const String editProfileEmailHint  = 'Enter email address';
  static const String editProfileMobileHint = '+91 9876543210';
  static const String editProfileAddressHint = 'Enter your address';

  // ── Drawer ───────────────────────────────────────────────────
  static const String drawerFeed           = 'Feed';
  static const String drawerMyRequests     = 'My Requests';
  static const String drawerHistory        = 'History';
  static const String drawerDonorDirectory = 'Donor Directory';
  static const String drawerNotifications  = 'Notifications';
  static const String drawerSupport        = 'Support';
  static const String drawerMyProfile      = 'My Profile';
  static const String drawerSignOut        = 'Sign Out';

  // ── Shell / AppBar ───────────────────────────────────────────
  static const Map<String, String> shellTitles = {
    '/home':            'Welcome!!',
    '/feed':            'Feed',
    '/my-requests':     'My Requests',
    '/donors':          'Donors',
    '/directory':       'Directory',
    '/history':         'History',
    '/profile':         'Profile',
    '/notifications':   'Notifications',
    '/add-requirement': 'New Blood Request',
    '/edit-profile':    'Edit Profile',
  };
  static const String shellDefaultTitle = 'BloodConnect';

  // ── Nav tabs ─────────────────────────────────────────────────
  static const String navHome     = 'Home';
  static const String navFeed     = 'Feed';
  static const String navRequests = 'Requests';
  static const String navDonors   = 'Donors';

  // ── Support screen ───────────────────────────────────────────
  static const String supportScreenTitle       = 'Contact Support';
  static const String supportAdminEmail        = 'hoffenmotoe2@gmail.com';
  static const String supportInfoTitle         = "We're here to help";
  static const String supportInfoBody          =
      "Having trouble logging in or need help? Send a message to our support team and we'll get back to you.";
  static const String supportNameLabel         = 'Your Name';
  static const String supportNameHint          = 'Your full name';
  static const String supportEmailLabel        = 'Your Email';
  static const String supportEmailHint         = 'your@email.com';
  static const String supportSubjectLabel      = 'Subject';
  static const String supportSubjectHint       = 'e.g. Cannot log in to my account';
  static const String supportMessageLabel      = 'Message';
  static const String supportMessageHint       = 'Describe your issue in detail…';
  static const String supportAttachLabel       = 'Attachments';
  static const String supportAttachSubtitle    = 'Optional — screenshots or files (max 5)';
  static const String supportAttachBtn         = 'Attach';
  static const String supportAttachDropzone    = 'Tap to attach a file';
  static const String supportAttachTypes       = 'Images, PDF, DOC, TXT';
  static const String supportSendBtn           = 'Send Message';
  static const String supportSentMsg           = 'Your message has been sent successfully! We\'ll get back to you soon.';
  static const String supportMaxFilesError     = 'You can attach a maximum of 5 files.';
  static const String supportPickerError       = 'Could not open file picker. Please try again.';
  static const String supportNoMailApp         = 'No mail app found. Admin email copied to clipboard: ';
  static const String supportEmailSubjectPrefix = '[HSBlood Support] ';
  static const String supportEmailBodySuffix    = '\n\n---\nSent via HSBlood Mobile App';

  // ── Common / Shared ──────────────────────────────────────────
  static const String commonCallBtn       = 'Call';
  static const String commonBackToFeed    = 'Back to feed';
  static const String commonClose         = 'Close';
  static const String commonCancel        = 'Cancel';
  static const String commonUpdate        = 'Update';
  static const String commonTryAgain      = 'Try again';
  static const String commonErrorRetry    = 'Something went wrong. Please try again.';
  static const String commonFailedConfirm = 'Failed to confirm. Please try again.';

  // ── Requirement detail — info tile labels ───────────────────
  static const String detailUnitsNeeded   = 'Units needed';
  static const String detailPatient       = 'Patient';
  static const String detailUrgency       = 'Urgency';
  static const String detailStatus        = 'Status';
  static const String detailNotFound      = 'Request not found.';
  static const String detailNotSpecified  = 'Not specified';

  // ── Directory — category keys (used in logic, not just labels) ─
  static const String dirCatAll       = 'All';
  static const String dirCatHospital  = 'Hospital';
  static const String dirCatBloodBank = 'Blood Bank';
  static const String dirCatAmbulance = 'Ambulance';

  // ── Donor detail popup — field labels ───────────────────────
  static const String donorFieldPhone       = 'Phone';
  static const String donorFieldAddress     = 'Address';
  static const String donorFieldCity        = 'City';
  static const String donorFieldLastDonation = 'Last Donation';
  static const String donorFieldRegistered  = 'Registered';

  // ── Feed filter popup buttons ────────────────────────────────
  static const String feedFilterClear = 'Clear';
  static const String feedFilterApply = 'Apply';

  // ── My Requests — status labels and dialog ───────────────────
  static const String myReqStatusFulfilled = 'Fulfilled';
  static const String myReqStatusCancelled = 'Cancelled';
  static const String myReqStatusOpen      = 'Open';
  static const String myReqCloseAction     = 'Close';
  static const String myReqCancelAction    = 'Cancel';

  // ── Pledge schedule modal ────────────────────────────────────
  static const String pledgeModalTitle         = 'Confirm Pledge';
  static const String pledgeModalSubtitle      = 'Choose when you plan to donate';
  static const String pledgeModalOptionalNote  = 'Scheduling is optional — you can pledge now and coordinate with the hospital directly.';
  static const String pledgeModalScheduleLabel = 'SCHEDULE (OPTIONAL)';
  static const String pledgeModalDateLabel   = 'Donation Date';
  static const String pledgeModalTimeLabel   = 'Preferred Time';
  static const String pledgeModalDateHint    = 'Pick date';
  static const String pledgeModalTimeHint    = 'Pick time';
  static const String pledgeModalConfirmBtn  = 'Pledge to Donate';
  static const String pledgeModalCancelBtn   = 'Cancel';
  static const String pledgeModalDateError   = 'Please select a donation date.';
  static const String pledgeModalTimeError   = 'Please select a preferred time.';

  // ── Cooldown / eligibility banner on feed ────────────────────
  static const String cooldownBannerTitle    = 'Not eligible to donate yet';
  static const String cooldownBannerPrefix   = 'Next eligible date: ';
  static const String cooldownBannerSuffix   = ' remaining';

  // ── Donor list in status modal ───────────────────────────────
  static const String donorListSectionTitle  = 'DONORS WHO RESPONDED';
  static const String donorListEmpty         = 'No donors have pledged yet.';
  static const String donorListLoading       = 'Loading donors…';
  static const String donorListError         = 'Could not load donor list.';
  static const String donorTabPledged        = 'Pledged Donors';
  static const String donorScheduledPrefix   = 'Scheduled: ';
  static const String donorNoSchedule        = 'No date scheduled';
  static const String donorMarkCompleted     = 'Mark Completed';
  static const String donorRevertPending     = 'Revert to Pending';
  static const String donorCompletedSuccess  = 'Marked as Completed!';
  static const String donorPendingSuccess    = 'Reverted to Pending.';
  static const String donorStatusError       = 'Failed to update status.';

  // ── Donation status badges ───────────────────────────────────
  static const String donationStatusPending   = 'Pending';
  static const String donationStatusCompleted = 'Completed';

  // ── Pending count label on My Requests card ──────────────────
  static const String pendingCountSuffix = ' pending approval';

  // ── Request status modal — stat card labels ──────────────────
  static const String modalDonorsLabel        = 'Donors';
  static const String modalUnitsRemainingLabel = 'Units Remaining';
  static const String modalFulfilledLabel     = 'Fulfilled';
  static const String modalUrgencyLabel       = 'Urgency';
  static const String modalContactLabel       = 'Contact';
  static const String modalLocationLabel      = 'Location';
  static const String modalNotesLabel         = 'Notes';

  // ── Profile dialog buttons ───────────────────────────────────
  static const String profileDialogCancel = 'Cancel';
  static const String profileDialogUpdate = 'Update';

  // ── Support screen — Quick Help section ─────────────────────
  static const String quickHelpTitle          = 'QUICK HELP';
  static const String quickHelpLoginTitle     = 'Login Issues';
  static const String quickHelpLoginBody      =
      'Contact your HSBlood administrator to reset your credentials. Accounts are centrally managed.';
  static const String quickHelpNewAccTitle    = 'New Account';
  static const String quickHelpNewAccBody     =
      'To register as a donor, reach out to your HSBlood administrator. Self-registration is not available.';
  static const String quickHelpNotifTitle     = 'Notifications';
  static const String quickHelpNotifBody      =
      'Ensure notifications are enabled in your device Settings for BloodConnect to receive blood request alerts.';

  // ── Share feature ────────────────────────────────────────────
  static const String shareBtn             = 'Share';
  static const String shareSubject         = 'Urgent Blood Request — $appName';

  static String shareText({
    required String bloodType,
    required String hospital,
    required String location,
    required String urgency,
    required String units,
    required String contactPhone,
  }) {
    final loc = location.isNotEmpty ? '\n📍 $location' : '';
    return '🩸 *$urgency Blood Request*\n\n'
        'Blood Type: *$bloodType*\n'
        'Hospital: $hospital$loc\n'
        'Units needed: $units\n'
        'Contact: $contactPhone\n\n'
        'Please share to help save a life!\n'
        'Download $appName to respond.';
  }

  // ── Home screen banner carousel ──────────────────────────────
  // Add or remove image paths here to control what appears in the carousel.
  // All paths must be declared under flutter › assets in pubspec.yaml.
  // The carousel will show exactly as many slides as there are entries.
  static const List<String> carouselImages = [
    'assets/images/banner_1.png',
    'assets/images/banner_2.png',
    'assets/images/banner_3.png',
    'assets/images/banner_4.png',
  ];
}
