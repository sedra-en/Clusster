import 'package:flutter/material.dart';

enum UserRole { admin, instructor, student }
enum UserStatus { active, pending, blocked }

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final UserStatus status;
  final bool isActivated;
  final DateTime createdAt;
  final String? activationCode;
  final String? studentId;
  final String? employeeId;

  AppUser({
    required this.id, required this.fullName, required this.email,
    required this.role, required this.status, required this.isActivated,
    required this.createdAt, this.activationCode, this.studentId, this.employeeId,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      isActivated: map['is_activated'].toString() == "1" || map['isActivated'] == true,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      activationCode: map['activation_code']?.toString(),
      studentId: map['student_id']?.toString(),
      employeeId: map['employee_id']?.toString(),
      role: _parseRole(map['role']),
      status: _parseStatus(map['status']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'full_name': fullName, 'email': email, 'role': role.name,
      'status': status.name, 'is_activated': isActivated ? 1 : 0,
      'created_at': createdAt.toIso8601String(), 'activation_code': activationCode,
    };
  }

  static UserRole _parseRole(dynamic role) {
    String r = role.toString().toLowerCase();
    if (r.contains('admin')) return UserRole.admin;
    if (r.contains('instructor')) return UserRole.instructor;
    return UserRole.student;
  }

  static UserStatus _parseStatus(dynamic status) {
    String s = status.toString().toLowerCase();
    if (s.contains('active')) return UserStatus.active;
    if (s.contains('blocked')) return UserStatus.blocked;
    return UserStatus.pending;
  }
}