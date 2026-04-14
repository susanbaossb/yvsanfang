import '../core/supabase_client.dart';
import '../models/user_profile.dart';


class PointsService {
  Future<List<UserProfile>> fetchAllProfiles() async {
    final rows = await AppSupabase.client
        .from('profiles')
        .select('id,nickname,role,points')
        .order('nickname', ascending: true);

    return rows
        .map<UserProfile>((row) => UserProfile.fromJson(row))
        .toList();

  }

  Future<int> fetchMyPoints(String userId) async {

    final row = await AppSupabase.client
        .from('profiles')
        .select('points')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return 0;
    return (row['points'] as int?) ?? 0;
  }

  String _todayDateStringUtc() {
    final now = DateTime.now().toUtc();
    final d = DateTime.utc(now.year, now.month, now.day);
    return d.toIso8601String().substring(0, 10); // YYYY-MM-DD
  }

  int _rewardForDate(DateTime dateUtc) {
    final day = dateUtc.day;
    if (day <= 5) return 10;
    if (day <= 10) return 20;
    // 规则按每月30天计算，超过的天数也按30积分处理
    return 30;
  }

  Future<bool> isCheckedInToday(String userId) async {
    final dateStr = _todayDateStringUtc();
    final row = await AppSupabase.client
        .from('daily_checkins')
        .select('id')
        .eq('user_id', userId)
        .eq('date', dateStr)
        .maybeSingle();
    return row != null;
  }


  Future<int> dailyCheckIn(String userId) async {
    final nowUtc = DateTime.now().toUtc();
    final dateOnly = _todayDateStringUtc();

    // 不允许补签：仅当日可签，若已存在则直接返回当前积分
    final exists = await AppSupabase.client
        .from('daily_checkins')
        .select('id')
        .eq('user_id', userId)
        .eq('date', dateOnly)
        .maybeSingle();
    if (exists != null) {
      return await fetchMyPoints(userId);
    }

    final reward = _rewardForDate(nowUtc);

    await AppSupabase.client.from('daily_checkins').insert({
      'user_id': userId,
      'date': dateOnly,
    });

    final current = await fetchMyPoints(userId);
    final newVal = current + reward;
    final row = await AppSupabase.client
        .from('profiles')
        .update({'points': newVal})
        .eq('id', userId)
        .select('points')
        .single();
    return row['points'] as int? ?? newVal;
  }


  Future<Set<String>> fetchMonthCheckins(String userId, int year, int month) async {
    final start = DateTime.utc(year, month, 1).toIso8601String().substring(0, 10);
    final end = DateTime.utc(month == 12 ? year + 1 : year, month == 12 ? 1 : month + 1, 1)
        .toIso8601String()
        .substring(0, 10);

    final rows = await AppSupabase.client
        .from('daily_checkins')
        .select('date')
        .eq('user_id', userId)
        .gte('date', start)
        .lt('date', end);

    final set = <String>{};
    for (final r in rows) {
      final d = r['date']?.toString();
      if (d != null && d.isNotEmpty) {
        set.add(d.substring(0, 10));
      }
    }
    return set;
  }

  Future<int> changePoints({required String userId, required int delta}) async {
    if (delta == 0) {
      return fetchMyPoints(userId);
    }

    final current = await fetchMyPoints(userId);
    final newVal = current + delta;
    if (newVal < 0) {
      throw Exception('积分不能小于0');
    }

    final row = await AppSupabase.client
        .from('profiles')
        .update({'points': newVal})
        .eq('id', userId)
        .select('points')
        .single();
    return row['points'] as int? ?? newVal;
  }

  Future<int> deductPoints(String userId, int amount) async {
    return changePoints(userId: userId, delta: -amount);
  }
}


