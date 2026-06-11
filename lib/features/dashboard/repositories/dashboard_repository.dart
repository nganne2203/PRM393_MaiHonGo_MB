import '../../../core/network/api_client.dart';
import '../models/dashboard_summary.dart';

class DashboardRepository {
  final ApiClient apiClient;

  const DashboardRepository({
    required this.apiClient,
  });

  Future<DashboardSummary> getDashboardSummary() async {
    final response = await apiClient.dio.get('/dashboard/summary');
    return DashboardSummary.fromEnvelope(response.data);
  }
}
