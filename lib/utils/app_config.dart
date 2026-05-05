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
  static const String orgName          = 'TNBlood';
  static const String appVersion       = '1.0';
  static const String footerText       = '$appName · $orgName v$appVersion';

  // ── Splash ──────────────────────────────────────────────────
  static const String splashBrandBold  = 'TN';
  static const String splashBrandLight = 'Blood';
  static const String splashTagline    = 'Every drop counts.';

  // ── Login — OTP screen ──────────────────────────────────────
  static const String otpEyebrow       = 'Blood Donor Registry';
  static const String otpHeading       = 'Welcome\nback';
  static const String otpSubtext       = 'Sign in with your registered mobile\nnumber to see blood requests near you.';
  static const String otpContinueBtn   = 'Login with OTP →';
  static const String otpSwitchBtn     = 'Login with Username & Password';
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
  static const String detailCancelPledgeBtn          = 'Cancel Volunteer';
  static const String detailCancelPledgeConfirmTitle = 'Cancel your Volunteer?';
  static const String detailCancelPledgeConfirmBody  =
      'Are you sure you want to withdraw your Volunteer for this request?';

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
      'When you Volunteer to donate blood, your donations will appear here.';
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
  static const String addReqBloodTypeHint   = 'Select blood type';
  static const String addReqDateHint        = 'Select date (optional)';
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
  static const String drawerRewards        = 'Rewards';
  static const String drawerDonorDirectory = 'Hospital Directory';
  static const String drawerNotifications  = 'Notifications';
  static const String drawerSupport        = 'Support';
  static const String drawerHowItWorks     = 'How It Works';
  static const String drawerHowItWorksSub  = '5-step donation flow guide';
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
    '/rewards':         'Rewards',
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
  static const String supportEmailSubjectPrefix = '[TNBlood Support] ';
  static const String supportEmailBodySuffix    = '\n\n---\nSent via TNBlood Mobile App';

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
  static const String pledgeModalTitle         = 'Confirm Volunteer';
  static const String pledgeModalSubtitle      = 'Choose when you plan to donate';
  static const String pledgeModalOptionalNote  = 'Scheduling is optional — you can Volunteer now and coordinate with the hospital directly.';
  static const String pledgeModalScheduleLabel = 'SCHEDULE (OPTIONAL)';
  static const String pledgeModalDateLabel   = 'Donation Date';
  static const String pledgeModalTimeLabel   = 'Preferred Time';
  static const String pledgeModalDateHint    = 'Pick date';
  static const String pledgeModalTimeHint    = 'Pick time';
  static const String pledgeModalConfirmBtn  = 'Volunteer to Donate';
  static const String pledgeModalCancelBtn   = 'Cancel';
  static const String pledgeModalDateError   = 'Please select a donation date.';
  static const String pledgeModalTimeError   = 'Please select a preferred time.';

  // ── Cooldown / eligibility banner on feed ────────────────────
  static const String cooldownBannerTitle    = 'Not eligible to donate yet';
  static const String cooldownBannerPrefix   = 'Next eligible date: ';
  static const String cooldownBannerSuffix   = ' remaining';

  // ── Donor list in status modal ───────────────────────────────
  static const String donorListSectionTitle  = 'DONORS WHO RESPONDED';
  static const String donorListEmpty         = 'No donors have Volunteered yet.';
  static const String donorListLoading       = 'Loading donors…';
  static const String donorListError         = 'Could not load donor list.';
  static const String donorTabPledged        = 'Volunteered Donors';
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
      'Contact your TNBlood administrator to reset your credentials. Accounts are centrally managed.';
  static const String quickHelpNewAccTitle    = 'New Account';
  static const String quickHelpNewAccBody     =
      'To register as a donor, reach out to your TNBlood administrator. Self-registration is not available.';
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


  // ── Home screen ─────────────────────────────────────────────
  static const String homeGreetingMorning   = 'Good morning,';
  static const String homeGreetingAfternoon = 'Good afternoon,';
  static const String homeGreetingEvening   = 'Good evening,';
  static const String homeStatDonated       = 'DONATED';
  static const String homeStatRequests      = 'REQUESTS';
  static const String homeStatPending       = 'PENDING';
  static const String homeUrgentSectionTitle = 'Urgent near you';
  static const String homeUrgentSeeAll      = 'See all →';
  static const String homeUrgentEmpty       = 'No urgent requests near you within 25 kms';
  static const String homePendingAlertSingle = 'pending Volunteer on your requests — tap to review';
  static const String homePendingAlertPlural = 'pending Volunteers on your requests — tap to review';

  // ── App Update dialog ────────────────────────────────────────
  static const String updateOptionalTitle       = 'Update Available';
  static const String updateForceTitle          = 'Update Required';
  static const String updateOptionalVersionSuffix = 'is ready';
  static const String updateForceVersionSuffix  = 'is required to continue';
  static const String updateOptionalDesc        =
      'A new version of BloodConnect is available on the App Store & Play Store with improvements and fixes.';
  static const String updateForceDesc           =
      'This version of BloodConnect is no longer supported. Please update to continue using the app.';
  static const String updateWhatsNewLabel       = "WHAT'S NEW";
  static const String updateNowBtn              = 'Update Now';
  static const String updateLaterBtn            = 'Remind Me Later';
  static const String updateOptionalFooter      = 'You can also update later from the App Store';
  static const String updateForceFooter         = 'You must update to continue using BloodConnect';
  static const List<String> updateDefaultBullets = [
    'Performance and stability improvements',
    'Bug fixes',
    'Security updates',
  ];

  // ── Hardcoded strings moved from views ──────────────────────
  // login_screen
  static const String loginOrDivider  = 'or';
  static const String loginRegisterBtn = 'Register';

  // register_screen
  static const String regCityLabel    = 'CITY *';
  static const String regCityHint     = 'e.g. Coimbatore';

  // edit_profile_screen
  static const String editCityLabel   = 'City';
  static const String editCityHint    = 'e.g. Coimbatore';
  static const String editUpdateFailed = 'Update failed.';

  // add_requirement_screen
  static const String addReqPatientLabel   = 'Patient';
  static const String addReqPatientHint    = 'Patient name *';
  static const String addReqHospitalHint   = 'Hospital *';
  static const String addReqLocationHint   = 'Location (optional)';
  static const String addReqContactLabel   = 'Contact';
  static const String addReqContactHint    = 'Contact person *';
  static const String addReqPhoneHint      = 'Phone *';
  static const String addReqBloodLabel     = 'Blood details';
  static const String addReqNotesHint      = 'Notes (optional)';
  static const String addReqStatusLabel    = 'Status';
  static const String addReqCancelBtn      = 'Cancel';
  static const String addReqConfirmBtn     = 'Confirm';
  static const String addReqUnitSingular   = 'unit';
  static const String addReqUnitPlural     = 'units';

  // my_requests_screen
  static const String myReqOpenChip        = 'Open';
  static const String myReqPledgedDonors   = 'Volunteer Donors';

  // pledged_donors_modal
  static const String pledgedUndoLabel          = 'Undo';
  static const String pledgedPendingLabel        = 'Pending';
  static const String pledgedCompletedLabel      = 'Completed';
  static const String pledgedPendingApprovalGroup = 'PENDING APPROVAL';
  static const String pledgedCompletedGroup      = 'COMPLETED';

  // request_status_modal
  static const String reqStatusModalTitle   = 'Request Status';
  static const String reqDonationProgress   = 'Donation Progress';

  // feed_screen
  static const String feedLocationFilter    = 'Location Filter';
  static const String feedViewList          = 'List';
  static const String feedViewMap           = 'Map';

  // requirement_detail_screen & requirement_card
  static const String reqKeepPledge         = 'Keep Volunteer';
  static const String reqCancelPledgeFailed = 'Failed to cancel Volunteer. Please try again.';

  // history_screen
  static const String historyRequestPrefix  = 'Request: ';

  // eligibility_card
  static const String eligibilityTitle      = 'Donation eligibility';
  static const String eligibilityZero       = '0';
  static const String eligibilityMaxDays    = '90 days';
  static const String eligibilityReadyTitle = 'Ready to donate!';
  static const String eligibilityReadyBody  = 'You are currently eligible to donate blood.';

  // donors_screen
  static const String donorsAvailableFilter    = 'Available';
  static const String donorsAllFilter          = 'All Donors';

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

  // ── How It Works screen ──────────────────────────────────────
  static const String hiwScreenTitle        = 'How It Works';
  static const String hiwSkipBtn            = 'Skip';
  static const String hiwPrevBtn            = '← Previous';
  static const String hiwNextBtn            = 'Next →';
  static const String hiwDoneBtn            = 'Got it ✓';
  static const String hiwImagePlaceholder   = 'Screenshot coming soon';
  static const List<Map<String, String>> hiwSlides = [
    {
      'step':     'STEP 1 OF 5',
      'title':    'Post a Blood Request',
      'desc':     'A requester creates a post with blood type, hospital, urgency level and number of units needed. The request goes live immediately on everyone\'s Feed.',
      'image':    'assets/images/how_it_works_1.png',
      'tipTitle': 'What happens next',
      'tipBody':  'The request is broadcast to all nearby eligible donors in real time.',
    },
    {
      'step':     'STEP 2 OF 5',
      'title':    'Nearby Donors Get Notified',
      'desc':     'Donors with a matching blood type receive a push notification and see the request card in their Feed with the "I\'ll Donate" button.',
      'image':    'assets/images/how_it_works_2.png',
      'tipTitle': 'Only eligible donors see this',
      'tipBody':  'Donors outside the 90-day cooldown period with a matching blood type receive the alert.',
    },
    {
      'step':     'STEP 3 OF 5',
      'title':    'Donor Volunteers & Schedules',
      'desc':     'Tapping "I\'ll Donate" opens the Schedule Pledge sheet. The donor optionally picks a date & time, then confirms their pledge.',
      'image':    'assets/images/how_it_works_3.png',
      'tipTitle': 'Status: Awaiting approval',
      'tipBody':  'The pledge shows as Pending until the requester confirms the donation was completed.',
    },
    {
      'step':     'STEP 4 OF 5',
      'title':    'Requester Confirms Donation',
      'desc':     'From My Requests, the requester taps "View Donors" and marks the pledge as Completed after the actual donation is done.',
      'image':    'assets/images/how_it_works_4.png',
      'tipTitle': 'Only the requester can confirm',
      'tipBody':  'The "Mark as Completed" button only appears in My Requests for the person who created the request.',
    },
    {
      'step':     'STEP 5 OF 5',
      'title':    'Request Fulfilled & History Saved',
      'desc':     'Once all units are confirmed, the request closes as Fulfilled. Both parties see it in History. The donor enters a 90-day cooldown.',
      'image':    'assets/images/how_it_works_5.png',
      'tipTitle': 'The cycle is complete',
      'tipBody':  'The blood bank is replenished and the community grows stronger with every donation.',
    },
  ];

  // ── Viewmodel error messages ─────────────────────────────────
  static const String errLoadRequirements   = 'Failed to load requirements.';
  static const String errLoadHistory        = 'Failed to load history. Please try again.';
  static const String errLoadNotifications  = 'Failed to load notifications.';
  static const String errLoadDonors         = 'Failed to load donors. Please try again.';
  static const String errLoadDirectory      = 'Failed to load directory.';
  static const String errLoadStats          = 'Failed to load stats.';
  static const String errLoadMyRequests     = 'Failed to load your requests.';
  static const String errUpdateRequest      = 'Failed to update request.';
  static const String errCloseRequest       = 'Failed to close request.';
  static const String errDeleteAccount      = 'Could not delete account. Please try again.';
  static const String errLoginFailed        = 'Login failed. Please try again.';
  static const String errInvalidCredentials = 'Invalid username or password.';
  static const String errLoadDetail         = 'Could not load request details.';
  static const String errCityRequired       = 'Please enter your city for location-based matching.';

  // ── Auth validation messages (login/register in-screen) ──────
  static const String valMobileRequired     = 'Please enter your mobile number.';
  static const String valMobileInvalid      = 'Enter a valid 10-digit Indian mobile number.';
  static const String valFillAllFields      = 'Please fill in all fields.';
  static const String valEmailInvalid       = 'Please enter a valid email.';
  static const String valPasswordTooShort   = 'Password must be at least 6 characters.';
  static const String valEmailRequired      = 'Enter a valid email address.';
  static const String valNameRequired       = 'Your name is required.';
  static const String valSubjectRequired    = 'Subject is required.';
  static const String valMessageRequired    = 'Message is required.';
  static const String valEditEmailInvalid   = 'Enter a valid email';
  static const String valPasswordMismatch   = 'Passwords do not match';
  static const String valFieldRequired      = 'Required';
  static const String valMinSixChars        = 'Min 6 characters';

  // ── Feed screen inline strings ───────────────────────────────
  static const String feedNearby            = 'Nearby';
  static const String feedNoResults         = 'No results';
  static const String feedNoRequestsForType = 'No {type} requests';
  static const String feedNoRequestsFound   = 'No requests found';
  static const String feedTryDifferent      = 'Try a different hospital name or blood type.';
  static const String feedExpandLocation    = 'No requests nearby. Try expanding the location filter.';
  static const String feedNoneNow           = 'No open requests for {type} right now.';
  static const String feedNoneAtAll         = 'No open blood requests right now.';
  static const String feedLocationWarning   = 'Location access not granted. Distance-based filters use your profile city.';
  static const String feedOpenLabel         = 'open';
  static const String feedNotMyType         = 'Not my type';

  // ── Requirement card inline strings ─────────────────────────
  static const String cardStillNeeded       = '{n} unit{s} still needed';
  static const String cardUpdateAvailability = 'Update availability in Profile';
  static const String cardDonorsResponded   = '{n} donor{s} responded';

  // ── Accepted screen ──────────────────────────────────────────
  static const String acceptedBackToFeed    = 'Back to feed';

  // ── Requirement detail screen ────────────────────────────────
  static const String detailDirectionsBtn   = 'Directions';

  // ── History screen ───────────────────────────────────────────
  static const String historyBloodDonation  = 'Blood Donation';

  // ── Directory screen ─────────────────────────────────────────
  static const String dirFilterTitle        = 'Filter Directory';
  static const String dirAvailability       = 'AVAILABILITY';
  static const String dirAvail24h           = '24h Open';
  static const String dirNotAvail24h        = 'Not 24h';
  static const String dirClearFilters       = 'Clear filters';
  static const String dirNoLocations        = 'No locations available for map view';
  static const String dirLocationDetails    = 'Location Details';
  static const String dirGetDirections      = 'Get Directions';
  static const String dirDetailPhone        = 'Phone';
  static const String dirDetailAddress      = 'Address';
  static const String dirDetailArea         = 'Area';
  static const String dirDetailAvailable    = 'Available';
  static const String dirDetailNotes        = 'Notes';
  static const String dirAvail24hValue      = '24 hours';
  static const String dirCheckTimings       = 'Check timings';
  static const String dirViewDetails        = 'View details';

  // ── Profile screen inline strings ───────────────────────────
  static const String profileDeleteBullet1  = 'Delete your login account';
  static const String profileDeleteBullet2  = 'Remove you from the donor list';
  static const String profileDeleteBullet3  = 'Delete all your notifications';
  static const String profileDeleteWarning  = 'This will permanently:';
  static const String profileDeleteIrreversible = 'This action cannot be undone.';
  static const String profileDeleteBtn      = 'Delete';
  static const String profileDeleteRemoves  = 'Removes your account and donor record';
  static const String profileUnitSuffix     = 'unit';
  static const String profileUnitPluralSuffix = 'units';
  static const String profileSuccessDialog  = 'Message Sent!';
  static const String profileSupportDone    = 'Done';

  // ── Donors screen inline strings ─────────────────────────────
  static const String donorUnavailableLabel = 'Unavailable';
  static const String donorNoScheduleSet    = 'No schedule set';

  // ── Pledged donors modal inline ───────────────────────────────
  static const String pledgedDonorCompleted = 'Completed';
  static const String pledgedDonorTotal     = '{n} total';

  // ── Request status modal inline ───────────────────────────────
  static const String reqStatusAwaitingApproval = '{n} donor{s} scheduled — awaiting your approval';
  static const String reqStatusFulfilled    = 'Fulfilled';
  static const String reqStatusCancelled    = 'Cancelled';
  static const String reqStatusOpen         = 'Open';

  // ── My requests screen section headers ───────────────────────
  static const String myReqSectionActive    = 'Active';

  // ── Schedule pledge modal ────────────────────────────────────
  static const String pledgeClearBtn        = 'Clear';

  // ── FCM / notification channel ────────────────────────────────
  static const String fcmChannelName        = 'Blood Alerts';
  static const String fcmChannelDesc        = 'Notifications for blood donation requests';
  static const String reminderChannelName   = 'Donation Reminders';
  static const String reminderChannelDesc   = 'Reminders for when you can donate blood again';
  static const String reminderTitle         = 'You can donate blood soon! 🩸';
  static const String reminderBody          = 'Check BloodConnect for active blood requests.';

  // ── Location filter labels ───────────────────────────────────
  static const String locationFilter5km     = '5 km';
  static const String locationFilter10km    = '10 km';
  static const String locationFilter25km    = '25 km';
  static const String locationFilter50km    = '50 km';
  static const String locationFilterMyCity  = 'My City';
  static const String locationFilterAll     = 'All Locations';

  // ── Feed map view ─────────────────────────────────────────────
  static const String feedMapNoRequests     = 'No requests on map';
  static const String feedMapNoLocation     = 'Requests without location data won\'t appear on the map.';

  // ── App name (used in main.dart) ─────────────────────────────
  static const String mainAppTitle          = 'BloodConnect';

  // ── Support screen validation messages ───────────────────────
  static const String supportSupportDone    = 'Done';
  static const String supportMsgSent        = 'Message Sent!';

  // ── Gamification — model strings ─────────────────────────────
  // Tiers
  static const String tierBronze   = 'Bronze';
  static const String tierSilver   = 'Silver';
  static const String tierGold     = 'Gold';
  static const String tierPlatinum = 'Platinum';
  static const String tierLegend   = 'Legend';

  // Badge names & descriptions
  static const String badgeFirstDropName        = 'First drop';
  static const String badgeFirstDropDesc        = 'Completed your first donation';
  static const String badgeFirstDropEarn        = 'Complete your first donation';
  static const String badgeLifeSaverName        = 'Life saver';
  static const String badgeLifeSaverDesc        = 'Helped 3 patients get their required blood';
  static const String badgeLifeSaverEarn        = 'Help 3 patients by donating';
  static const String badgeStreak3Name          = 'Streak 3';
  static const String badgeStreak3Desc          = 'Donated for 3 consecutive eligible months';
  static const String badgeStreak3Earn          = 'Donate for 3 months in a row';
  static const String badgeOnTimeName           = 'On time';
  static const String badgeOnTimeDesc           = 'Showed up on the exact scheduled date';
  static const String badgeOnTimeEarn           = 'Complete a donation on the scheduled date';
  static const String badgeRapidName            = 'Rapid responder';
  static const String badgeRapidDesc            = 'Pledged to a Critical request within 1 hour';
  static const String badgeRapidEarn            = 'Pledge to a Critical request within 1 hour';
  static const String badgePlatinumName         = 'Platinum';
  static const String badgePlatinumDesc         = 'Reached Platinum donor tier (15 donations)';
  static const String badgePlatinumEarn         = 'Reach 15 donations to unlock Platinum';
  static const String badgeLegendName           = 'Legend';
  static const String badgeLegendDesc           = 'Reached Legend tier (25+ donations)';
  static const String badgeLegendEarn           = 'Reach 25 donations to become a Legend';

  // Challenge names & descriptions
  static const String challengeCityChampionTitle     = 'City champion';
  static const String challengeCityChampionDesc      = 'Reach #1 on your city leaderboard this month';
  static const String challengeBloodTypeHeroTitle    = 'Blood type hero';
  static const String challengeBloodTypeHeroDesc     = 'Donate to requests from 3 different blood types in a month';
  static const String challengeEmergencyTitle        = 'Emergency responder';
  static const String challengeEmergencyDesc         = 'Pledge to a Critical-urgency request within 1 hour of it being posted';
  static const String challengeRapidPledgeTitle      = 'Rapid pledge';
  static const String challengeRapidPledgeDesc       = 'Complete a scheduled donation within the agreed date and time';
  static const String challengeFirstPledgeTitle      = 'First pledge';
  static const String challengeFirstPledgeDesc       = 'Make your very first donation pledge on BloodConnect';
  static const String challengeLifeSaverTitle        = 'Life saver';
  static const String challengeLifeSaverDesc         = 'Help 3 patients by completing donations';

  // Gamification UI strings
  static const String gamificationRewardsTitle   = 'Rewards';
  static const String gamificationLeaderboard    = 'Leaderboard';
  static const String gamificationChallenges     = 'Challenges';
  static const String gamificationBadges         = 'Badges';
  static const String gamificationMyCity         = 'My city';
  static const String gamificationState          = 'State';
  static const String gamificationAllIndia       = 'All India';
  static const String gamificationDonor          = 'Donor';
  static const String gamificationDonations      = 'Donations';
  static const String gamificationXp             = 'XP';
  static const String gamificationYou            = 'You';
  static const String gamificationYouTag         = 'you';
  static const String gamificationDaysLeft       = 'days left';
  static const String gamificationOngoing        = 'Ongoing';
  static const String gamificationEarned         = 'Earned';
  static const String gamificationLocked         = 'Locked';
  static const String gamificationAll            = 'All';
  static const String gamificationActive         = 'Active';
  static const String gamificationCompleted      = 'Completed';
  static const String gamificationLegendReached  = 'Legend tier reached!';
  static const String gamificationFailedLoad     = 'Failed to load rewards';
  static const String gamificationFailedLoadVM   = 'Failed to load rewards. Please try again.';
  static const String gamificationTryAgain       = 'Try again';
  static const String gamificationStreakKeep     = 'Donate before {date} to keep it';
  static const String gamificationDonateToKeep   = 'days left';

  // Home screen — rewards tab
  static const String homeTabFeed              = 'Feed';
  static const String homeTabRewards           = 'Rewards';
  static const String homeRewardsLeaderboard   = 'Leaderboard';
  static const String homeRewardsChallenges    = 'Active challenges';
  static const String homeRewardsWelcome       = 'Welcome';
  static const String homeRewardsStreakKeep    = 'Donate before {date} to keep it';
  static const String homeRewardsXpToTier      = '{xp} XP to {tier}';
  static const String homeRewardsLegendReached = 'Legend tier reached!';
  static const String homeRewardsYou           = 'You';
  static const String homeRewardsDaysLeft      = 'days left';
  static const String homeRewardsCityLb        = 'City leaderboard';

  // Profile screen — gamification section
  static const String profileGamBadges         = 'Badges';
  static const String profileGamSeeAll         = 'See all';
  static const String profileGamCityLb         = 'City leaderboard';
  static const String profileGamThisMonth      = 'This month';
  static const String profileGamDonor          = 'Donor';
  static const String profileGamEligibleNow    = 'Eligible now!';
  static const String profileGamNow            = 'Now';
  static const String profileGamDonationElig   = 'Donation Eligibility';
  static const String profileDeleteFailed       = 'Failed to delete account. Please try again.';

  // Bottom nav shell labels (main_shell.dart)

  // Directory screen inline strings
  static const String directoryPhone    = 'Phone';
  static const String directoryAddress  = 'Address';
  static const String directoryArea     = 'Area';
  static const String directoryAvail    = 'Available';
  static const String directoryNotes    = 'Notes';

  // Feed/home inline

  // Widgets
  static const String widgetTryAgain   = 'Try again';
  static const String widgetUser       = 'User';

  // Password prompt dialog
  static const String pwdPromptTitle    = 'Secure Your Account';
  static const String pwdPromptBody     = 'You registered using a one-time code. Sign in with your username.';
  static const String pwdPromptUpdate   = 'Update Password';
  static const String pwdPromptSkip     = 'Skip for Now';

  // Eligibility card
  static const String eligCalc          = 'Calculating…';
  static const String eligReEligible    = 're eligible.';

  // Add requirement screen blood type labels
  static const String bloodTypeAPosLabel = 'Type A Positive';
  static const String bloodTypeANegLabel = 'Type A Negative';
  static const String bloodTypeBPosLabel = 'Type B Positive';
  static const String bloodTypeBNegLabel = 'Type B Negative';
  static const String bloodTypeOPosLabel = 'Type O Positive';
  static const String bloodTypeONegLabel = 'Type O Negative';
  static const String bloodTypeABPos     = 'AB+';
  static const String bloodTypeABNeg     = 'AB-';
  static const String addReqTooShort     = 'Too short';
  static const String addReqRequired     = 'Required';
  static const String addReqSelectBT     = 'Select blood type';
  static const String addReqUnitLabel    = 'unit';
  static const String addReqUnitsLabel   = 'units';
}