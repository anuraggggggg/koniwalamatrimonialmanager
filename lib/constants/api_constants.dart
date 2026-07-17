class ApiConstants {
  static const String baseUrl = 'https://app.koniwalamatrimonial.com/api/v1';
  static const String login = '/auth/mobile/login';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  static const String dashboardStats = '/profiles/dashboard/stats';

  static const String managerDashboard = '/dashboard/manager';

  static const String followUpControlMessage =
      '/dashboard/follow-up-control/message';
  static const String followUpControlVoiceNote =
      '/dashboard/follow-up-control/voice-note';

  static const String followUpControlMessageUrl =
      '$baseUrl$followUpControlMessage';
  static const String followUpControlVoiceNoteUrl =
      '$baseUrl$followUpControlVoiceNote';

  static const String rmDashboardSummary = '/dashboard/rm/summary';

  static const String dataEntryDashboard = '/dashboard/data-entry';

  static const String profiles = '/profiles';

  static const String tasks = '/tasks';

  static String task(String taskId) => '$tasks/${Uri.encodeComponent(taskId)}';

  static String profileMatchComparison(
    String profileId,
    String candidateProfileId,
  ) =>
      '/profiles/${Uri.encodeComponent(profileId)}/match-comparison/${Uri.encodeComponent(candidateProfileId)}';

  static String profileMatchHistory(String profileId) =>
      '/profiles/${Uri.encodeComponent(profileId)}/match-history';

  static const String matchingSuggestionsPersist =
      '/matching/suggestions/persist';

  // Lead Endpoints
  static const String leads = '/leads';

  static const String leadFollowUps = '/leads/follow-ups';

  static const String relationshipManagers = '/users/relationship-managers';

  static const String dataEntryUsers = '/users/data-entry';

  static String lead(String leadId) => '/leads/${Uri.encodeComponent(leadId)}';
  static String leadComments(String leadId) =>
      '/leads/${Uri.encodeComponent(leadId)}/comments';

  // Customer Endpoints
  static const String customers = '/customers';

  static String customer(String customerId) =>
      '/customers/${Uri.encodeComponent(customerId)}';

  // Shortlist Endpoints
  static String shortlistProfile(String profileId) =>
      '/shortlists/profile/${Uri.encodeComponent(profileId)}';

  static String shortlistProfileCandidates(String profileId) =>
      '${shortlistProfile(profileId)}/candidates';

  static const String shortlistsSend = '/shortlists/send';

  static String shortlistCandidate(String candidateId) =>
      '/shortlists/candidates/${Uri.encodeComponent(candidateId)}';

  // HR Endpoints
  static const String hrEmployees = '/users/staff-list';

  static String hrEmployee(String employeeId) =>
      '/hr/employees/${Uri.encodeComponent(employeeId)}';

  static const String payrollPreview = '/hr/payroll/preview';
  static const String payrollRun = '/hr/payroll/runs';
  static const String payrollRecalculate = '/hr/payroll/recalculate';

  static String payrollPayslipDownload(String payslipId) =>
      '/hr/payroll/payslips/${Uri.encodeComponent(payslipId)}/download';

  static String payrollEmployeeHistory(String employeeId) =>
      '/hr/payroll/employees/${Uri.encodeComponent(employeeId)}/history';

  static const String hrAttendanceCalendar = '/hr/attendance/calendar';

  static const String hrHolidays = '/hr/holidays';

  static String hrEmployeeAttendance({
    required String employeeId,
    required int month,
    required int year,
  }) =>
      '/hr/attendance/employees/${Uri.encodeComponent(employeeId)}?month=$month&year=$year';

  static String hrLeaveStatus(String leaveId) =>
      '/hr/leaves/${Uri.encodeComponent(leaveId)}/status';

  static const String notifications = '/notifications';

  // WhatsApp Endpoints
  static const String whatsappSend = '/whatsapp/send';
  static const String whatsappConversations = '/whatsapp/conversations';
  static const String whatsappMessagesRead = '/whatsapp/messages/read';
  static const String whatsappTemplates = '/whatsapp/templates';
  static const String whatsappStatus = '/whatsapp/status';
  static const String whatsappProfilePicture = '/whatsapp/profile-picture';

  static String whatsappConversationMessages(String leadId) =>
      '$whatsappConversations/${Uri.encodeComponent(leadId)}/messages';

  static String whatsappConversationRead(String leadId) =>
      '$whatsappConversations/${Uri.encodeComponent(leadId)}/read';

  static String whatsappConversation(String leadId) =>
      '$whatsappConversations/${Uri.encodeComponent(leadId)}';

  static String whatsappMessage(String messageId) =>
      '/whatsapp/messages/${Uri.encodeComponent(messageId)}';

  static String whatsappMedia(String mediaId) =>
      '/whatsapp/media/${Uri.encodeComponent(mediaId)}';

  // External APIs
  static const String diceBearAvatar =
      'https://api.dicebear.com/7.x/avataaars/svg?seed=Felix';
}
