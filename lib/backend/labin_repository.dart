import 'package:supabase_flutter/supabase_flutter.dart';

class LabinRepository {
  LabinRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  bool get isReady => _client != null;

  String? get currentUserId => _client?.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchEquipment({
    String? categoryName,
    bool onlyAvailable = false,
  }) async {
    final client = _requireClient();
    var query = client
        .from('equipment')
        .select('''
      id,
      name,
      slug,
      specs,
      description,
      image_url,
      total_stock,
      borrowed_stock,
      condition_label,
      equipment_categories(name, icon_name, color_hex),
      labs(name)
    ''')
        .eq('is_active', true);

    if (onlyAvailable) {
      query = query.gt('total_stock', 0);
    }

    final rows = await query.order('name');
    final items = List<Map<String, dynamic>>.from(rows);
    if (categoryName == null || categoryName == 'Semua') return items;

    return items
        .where((item) => item['equipment_categories']?['name'] == categoryName)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final client = _requireClient();
    final rows = await client
        .from('rooms')
        .select('''
      id,
      name,
      capacity,
      availability_note,
      labs(name, building, floor),
      room_facilities(name, is_available)
    ''')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final client = _requireClient();
    final rows = await client
        .from('announcements')
        .select(
          'id, title, category, excerpt, content, is_pinned, published_at',
        )
        .order('is_pinned', ascending: false)
        .order('published_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('notifications')
        .select('id, type, title, message, data, read_at, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markNotificationRead(String notificationId) async {
    final client = _requireClient();
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  Future<String> createEquipmentLoan({
    required String equipmentId,
    required int quantity,
    required DateTime borrowDate,
    required DateTime returnDate,
    required String purpose,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();

    final loan = await client
        .from('equipment_loans')
        .insert({
          'borrower_id': userId,
          'purpose': purpose,
          'borrow_date': _dateOnly(borrowDate),
          'return_date': _dateOnly(returnDate),
          'status': 'pending',
        })
        .select('id')
        .single();

    await client.from('equipment_loan_items').insert({
      'loan_id': loan['id'],
      'equipment_id': equipmentId,
      'quantity': quantity,
    });

    return loan['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchMyLoans() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('equipment_loans')
        .select('''
      id,
      tracking_code,
      purpose,
      borrow_date,
      return_date,
      status,
      created_at,
      equipment_loan_items(
        quantity,
        equipment(name, specs, equipment_categories(name))
      )
    ''')
        .eq('borrower_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> createRoomReservation({
    required String roomId,
    required String activityName,
    required String activityType,
    required int participantCount,
    required DateTime startsAt,
    required DateTime endsAt,
    String? note,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final row = await client
        .from('room_reservations')
        .insert({
          'room_id': roomId,
          'requester_id': userId,
          'activity_name': activityName,
          'activity_type': activityType,
          'participant_count': participantCount,
          'starts_at': startsAt.toIso8601String(),
          'ends_at': endsAt.toIso8601String(),
          'note': note,
          'status': 'pending',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchMyReservations() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('room_reservations')
        .select('''
      id,
      activity_name,
      activity_type,
      participant_count,
      starts_at,
      ends_at,
      status,
      rooms(name, capacity, labs(name, building, floor))
    ''')
        .eq('requester_id', userId)
        .order('starts_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String> createDamageReport({
    required String facilityName,
    required String urgency,
    required String description,
    String? roomId,
  }) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final row = await client
        .from('damage_reports')
        .insert({
          'reporter_id': userId,
          'room_id': roomId,
          'facility_name': facilityName,
          'urgency': urgency,
          'description': description,
          'status': 'submitted',
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> fetchMyDamageReports() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final rows = await client
        .from('damage_reports')
        .select('''
      id,
      tracking_code,
      facility_name,
      urgency,
      description,
      status,
      created_at,
      rooms(name)
    ''')
        .eq('reporter_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> toggleEquipmentFavorite(String equipmentId) async {
    final client = _requireClient();
    final userId = _requireUserId();
    final existing = await client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('equipment_id', equipmentId)
        .maybeSingle();

    if (existing == null) {
      await client.from('favorites').insert({
        'user_id': userId,
        'equipment_id': equipmentId,
      });
      return;
    }

    await client.from('favorites').delete().eq('id', existing['id']);
  }

  Future<List<Map<String, dynamic>>> fetchStaffDashboard() async {
    final client = _requireClient();
    final userId = _requireUserId();
    final shifts = await client
        .from('staff_shifts')
        .select('''
      id,
      starts_at,
      ends_at,
      status,
      swap_requested,
      rooms(name, labs(name))
    ''')
        .eq('staff_id', userId)
        .order('starts_at');
    final tasks = await client
        .from('staff_tasks')
        .select('id, title, description, priority, status, due_at, rooms(name)')
        .eq('assignee_id', userId)
        .order('due_at');

    return [
      {'type': 'shifts', 'items': shifts},
      {'type': 'tasks', 'items': tasks},
    ];
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase belum dikonfigurasi.');
    }
    return client;
  }

  String _requireUserId() {
    final userId = currentUserId;
    if (userId == null) {
      throw StateError('User belum login.');
    }
    return userId;
  }

  String _dateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}
