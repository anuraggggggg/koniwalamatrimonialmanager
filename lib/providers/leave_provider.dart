import 'package:flutter/material.dart';
import 'package:koniwalamatrimonial/models/leave_model.dart';
import 'package:koniwalamatrimonial/services/leave_service.dart';

class LeaveProvider extends ChangeNotifier {
  final LeaveService _leaveService;
  List<LeaveModel> _leaves = [];
  List<LeaveModel> _myLeaves = [];
  bool _isLoading = false;
  final Set<String> _processingLeaveIds = <String>{};

  LeaveProvider(this._leaveService);

  List<LeaveModel> get leaves => _leaves;
  List<LeaveModel> get myLeaves => _myLeaves;
  bool get isLoading => _isLoading;
  bool isProcessingLeave(String leaveId) {
    return _processingLeaveIds.contains(leaveId);
  }

  void upsertLeave(LeaveModel leave) {
    if (leave.id.trim().isEmpty) {
      return;
    }

    _leaves = _upsertInto(_leaves, leave);
    notifyListeners();
  }

  void upsertMyLeave(LeaveModel leave) {
    if (leave.id.trim().isEmpty) {
      return;
    }

    _myLeaves = _upsertInto(_myLeaves, leave);
    notifyListeners();
  }

  List<LeaveModel> _upsertInto(List<LeaveModel> leaves, LeaveModel leave) {
    final existingIndex = leaves.indexWhere((item) => item.id == leave.id);
    if (existingIndex == -1) {
      return [leave, ...leaves];
    }

    return [
      for (var index = 0; index < leaves.length; index++)
        index == existingIndex ? leave : leaves[index],
    ];
  }

  Future<void> fetchLeaves(String token, {bool includeAll = true}) async {
    _isLoading = true;
    notifyListeners();
    _leaveService.setAccessToken(token);
    _leaves = includeAll
        ? await _leaveService.getAllLeaves()
        : await _leaveService.getMyLeaves();
    if (!includeAll) {
      _myLeaves = _leaves;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMyLeaves(String token) async {
    _isLoading = true;
    notifyListeners();
    _leaveService.setAccessToken(token);
    _myLeaves = await _leaveService.getMyLeaves();
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> approveLeave(String leaveId, String token) async {
    if (token.trim().isEmpty) {
      return 'Authorization token is missing.';
    }

    if (leaveId.trim().isEmpty) {
      return 'Leave id is missing.';
    }

    _processingLeaveIds.add(leaveId);
    notifyListeners();

    try {
      _leaveService.setAccessToken(token);
      await _leaveService.updateLeaveStatus(
        leaveId: leaveId,
        status: 'APPROVED',
      );
      _leaves = _leaves
          .map(
            (leave) => leave.id == leaveId
                ? leave.copyWith(status: 'APPROVED')
                : leave,
          )
          .toList();
      _myLeaves = _myLeaves
          .map(
            (leave) => leave.id == leaveId
                ? leave.copyWith(status: 'APPROVED')
                : leave,
          )
          .toList();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      _processingLeaveIds.remove(leaveId);
      notifyListeners();
    }
  }

  Future<String?> rejectLeave(String leaveId, String token) {
    return _updateLeaveStatus(leaveId, 'REJECTED', token);
  }

  Future<String?> deleteLeave(String leaveId) async {
    if (leaveId.trim().isEmpty) {
      return 'Leave id is missing.';
    }

    _processingLeaveIds.add(leaveId);
    notifyListeners();

    try {
      _leaves = _leaves.where((leave) => leave.id != leaveId).toList();
      _myLeaves = _myLeaves.where((leave) => leave.id != leaveId).toList();
      return null;
    } catch (_) {
      return 'Unable to delete leave application.';
    } finally {
      _processingLeaveIds.remove(leaveId);
      notifyListeners();
    }
  }

  Future<String?> _updateLeaveStatus(
    String leaveId,
    String status,
    String token,
  ) async {
    if (token.trim().isEmpty) {
      return 'Authorization token is missing.';
    }

    if (leaveId.trim().isEmpty) {
      return 'Leave id is missing.';
    }

    _processingLeaveIds.add(leaveId);
    notifyListeners();

    try {
      _leaveService.setAccessToken(token);
      await _leaveService.updateLeaveStatus(
        leaveId: leaveId,
        status: status,
      );
      _leaves = _leaves
          .map(
            (leave) => leave.id == leaveId
                ? leave.copyWith(status: status)
                : leave,
          )
          .toList();
      _myLeaves = _myLeaves
          .map(
            (leave) => leave.id == leaveId
                ? leave.copyWith(status: status)
                : leave,
          )
          .toList();
      return null;
    } catch (_) {
      return 'Unable to update leave status.';
    } finally {
      _processingLeaveIds.remove(leaveId);
      notifyListeners();
    }
  }
}
