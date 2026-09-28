import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/core/network/api_client.dart';

class RoleAdminService {
  static Future<List<RoleModel>> fetchRoles() async {
    final body = await ApiClient.get('/admin/roles');

    if (body is Map && body['data'] != null) {
      final paginated = body['data'];
      if (paginated is Map && paginated['data'] != null) {
        final List<dynamic> data = paginated['data'];
        return data
            .map((e) => RoleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    throw 'Format data role tidak sesuai.';
  }

  static Future<void> createRole(Map<String, dynamic> payload) async {
    await ApiClient.post('/admin/roles', body: payload);
  }

  static Future<void> updateRole(int id, Map<String, dynamic> payload) async {
    await ApiClient.put('/admin/roles/$id', body: payload);
  }

  static Future<void> deleteRole(int id) async {
    await ApiClient.delete('/admin/roles/$id');
  }

  static Future<AssignFormData> fetchAssignFormData() async {
    final decoded = await ApiClient.get('/admin/roles/assign-form-data');
    if (decoded is! Map) throw 'Format data assign tidak sesuai.';

    return AssignFormData.fromJson(Map<String, dynamic>.from(decoded));
  }

  static Future<void> assignRoleToUser({
    required int userId,
    required int roleId,
  }) async {
    await ApiClient.post(
      '/admin/roles/assign',
      body: {'user_id': userId, 'role_id': roleId},
    );
  }
}
