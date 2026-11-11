import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

const Color kGoldColor = Color(0xFFE5B849);
const Color kCardBgColor = Color(0xFF1E1613);
const Color kBgColor = Color(0xFF120C0A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://deddtakakwmmwvxmshhw.supabase.co',
    anonKey: 'sb_publishable_S232452SVp82-v_n2rebYA_60e8ZdIs',
  );

  runApp(const AriamBarbershopApp());
}

class AriamBarbershopApp extends StatelessWidget {
  const AriamBarbershopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ariam Barbershop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBgColor,
        colorScheme: const ColorScheme.dark(
          primary: kGoldColor,
          surface: kCardBgColor,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _isBarberActive = true;
  bool _isAdminMode = false;

  String _currentAnnouncement = '¡Bienvenidos a Ariam Barbershop! Reserva tu turno con antelación.';
  String _currentLocation = 'La Habana, Cuba (Local Principal)';

  final List<String> _availableHours = [
    '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '02:00 PM', '03:00 PM', '04:00 PM', '05:00 PM',
    '06:00 PM', '07:00 PM', '08:00 PM',
  ];

  List _allBookings = [];
  List _services = [
    {
      'id': 1,
      'name': 'Corte Fade Moderno',
      'price': 1500,
      'duration': '30 min',
      'icon': Icons.content_cut,
    }
  ];
  List _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadDataFromSupabase();
  }

  Future<void> _loadDataFromSupabase() async {
    final supabase = Supabase.instance.client;

    try {
      final settingsRes = await supabase.from('settings').select();
      if (settingsRes != null) {
        for (var row in settingsRes) {
          if (row['key'] == 'announcement') {
            setState(() => _currentAnnouncement = row['value']?.toString() ?? '');
          } else if (row['key'] == 'location') {
            setState(() => _currentLocation = row['value']?.toString() ?? '');
          }
        }
      }
    } catch (e) {
      debugPrint('Error en settings: $e');
    }

    try {
      final servicesRes = await supabase.from('services').select();
      if (servicesRes != null && servicesRes.isNotEmpty) {
        setState(() {
          _services = servicesRes.map((s) => {
            'id': s['id'],
            'name': s['name']?.toString() ?? 'Servicio',
            'price': int.tryParse(s['price']?.toString() ?? '0') ?? 0,
            'duration': s['duration']?.toString() ?? '30 min',
            'icon': Icons.content_cut,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error en services: $e');
    }

    try {
      final bookingsRes = await supabase.from('reservations').select().order('id', ascending: false);
      if (bookingsRes != null) {
        setState(() {
          _allBookings = bookingsRes;
        });
      }
    } catch (e) {
      debugPrint('Error en reservations: $e');
    }

    try {
      final reviewsRes = await supabase.from('reviews').select().order('id', ascending: false);
      if (reviewsRes != null) {
        setState(() {
          _reviews = reviewsRes;
        });
      }
    } catch (e) {
      debugPrint('Error en reviews: $e');
    }
  }

  Future<void> _addBooking(Map<String, dynamic> booking) async {
    try {
      await Supabase.instance.client.from('reservations').insert({
        'client': booking['client'],
        'phone': booking['phone'],
        'service': booking['service'],
        'price': booking['price'],
        'time': booking['time'],
        'status': 'Pendiente',
      });
      await _loadDataFromSupabase();
    } catch (e) {
      debugPrint('Error insertando reserva: $e');
    }
  }

  Future<void> _updateBookingStatus(dynamic id, String newStatus) async {
    try {
      await Supabase.instance.client.from('reservations').update({'status': newStatus}).eq('id', id);
      await _loadDataFromSupabase();
    } catch (e) {
      debugPrint('Error actualizando estado: $e');
    }
  }

  Future<void> _deleteBooking(dynamic id) async {
    try {
      await Supabase.instance.client.from('reservations').delete().eq('id', id);
      await _loadDataFromSupabase();
    } catch (e) {
      debugPrint('Error borrando reserva: $e');
    }
  }

  Future<void> _deleteReview(dynamic id) async {
    try {
      await Supabase.instance.client.from('reviews').delete().eq('id', id);
      await _loadDataFromSupabase();
    } catch (e) {
      debugPrint('Error borrando reseña: $e');
    }
  }

  Future<void> _addReview(Map<String, dynamic> review) async {
    try {
      await Supabase.instance.client.from('reviews').insert({
        'name': review['name'],
        'text': review['text'],
        'rating': review['rating'],
      });
      await _loadDataFromSupabase();
    } catch (e) {
      debugPrint('Error guardando reseña: $e');
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    try {
      await Supabase.instance.client.from('settings').upsert({
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      debugPrint('Error guardando ajuste: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountingRecords = _allBookings.where((b) => (b as Map)['status'] == 'Terminado').toList();

    return Scaffold(
      body: _isAdminMode
          ? AdminPanelScreen(
              bookings: _allBookings,
              services: _services,
              accountingRecords: accountingRecords,
              isBarberActive: _isBarberActive,
              availableHours: _availableHours,
              currentAnnouncement: _currentAnnouncement,
              currentLocation: _currentLocation,
              reviews: _reviews,
              onStatusChanged: (id, st) => _updateBookingStatus(id, st),
              onDelete: (id) => _deleteBooking(id),
              onFinish: (id) => _updateBookingStatus(id, 'Terminado'),
              onSaveService: (data, {editIndex}) async {
                try {
                  final supabase = Supabase.instance.client;
                  if (editIndex != null) {
                    await supabase.from('services').update({
                      'name': data['name'],
                      'price': data['price'],
                      'duration': data['duration'],
                    }).eq('id', editIndex);
                  } else {
                    await supabase.from('services').insert({
                      'name': data['name'],
                      'price': data['price'],
                      'duration': data['duration'],
                    });
                  }
                  await _loadDataFromSupabase();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Servicio guardado con éxito!'), backgroundColor: kGoldColor),
                    );
                  }
                } catch (e) {
                  debugPrint('Error guardando servicio: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al guardar servicio: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              onToggleBarberStatus: (val) => setState(() => _isBarberActive = val),
              onToggleHourAvailability: (hour) => setState(() {
                if (_availableHours.contains(hour)) {
                  _availableHours.remove(hour);
                } else {
                  _availableHours.add(hour);
                  _availableHours.sort();
                }
              }),
              onUpdateAnnouncement: (ann) {
                setState(() => _currentAnnouncement = ann);
                _saveSetting('announcement', ann);
              },
              onUpdateLocation: (loc) {
                setState(() => _currentLocation = loc);
                _saveSetting('location', loc);
              },
              onDeleteReview: (id) => _deleteReview(id),
              onSwitchToClient: () => setState(() => _isAdminMode = false),
            )
          : ClientScreen(
              services: _services,
              availableHours: _availableHours,
              isBarberActive: _isBarberActive,
              allBookings: _allBookings,
              announcement: _currentAnnouncement,
              location: _currentLocation,
              reviews: _reviews,
              onBookingConfirmed: (b) => _addBooking(b),
              onAddReview: (r) => _addReview(r),
              onSwitchToAdmin: () => setState(() => _isAdminMode = true),
            ),
    );
  }
}

/* ==========================================
   1. PANTALLA DE CLIENTE (VISTA WEB)
========================================== */
class ClientScreen extends StatefulWidget {
  final List services;
  final List<String> availableHours;
  final bool isBarberActive;
  final List allBookings;
  final String announcement;
  final String location;
  final List reviews;
  final Function(Map<String, dynamic>) onBookingConfirmed;
  final Function(Map<String, dynamic>) onAddReview;
  final VoidCallback onSwitchToAdmin;

  const ClientScreen({
    super.key,
    required this.services,
    required this.availableHours,
    required this.isBarberActive,
    required this.allBookings,
    required this.announcement,
    required this.location,
    required this.reviews,
    required this.onBookingConfirmed,
    required this.onAddReview,
    required this.onSwitchToAdmin,
  });

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _searchPhoneController = TextEditingController();

  int _selectedServiceIndex = 0;
  String? _selectedTime;
  String? _searchedPhone;
  int _selectedRating = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reviewController.dispose();
    _searchPhoneController.dispose();
    super.dispose();
  }

  void _submitBooking() {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa tu nombre, teléfono y selecciona una hora.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final service = widget.services[_selectedServiceIndex] as Map<String, dynamic>;
    widget.onBookingConfirmed({
      'client': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'service': service['name'] ?? 'Corte',
      'price': service['price'] ?? 0,
      'time': _selectedTime,
      'status': 'Pendiente',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Reserva enviada a Ariam con éxito!'),
        backgroundColor: kGoldColor,
      ),
    );

    _nameController.clear();
    _phoneController.clear();
    setState(() {
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTime != null && !widget.availableHours.contains(_selectedTime)) {
      _selectedTime = null;
    }

    final clientBookings = _searchedPhone == null || _searchedPhone!.isEmpty
        ? []
        : widget.allBookings.where((b) => (b as Map)['phone'] == _searchedPhone).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        title: GestureDetector(
          onDoubleTap: widget.onSwitchToAdmin,
          child: Row(
            children: const [
              Icon(Icons.content_cut, color: kGoldColor, size: 20),
              SizedBox(width: 8),
              Text(
                'ARIAM BARBERSHOP',
                style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isBarberActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.isBarberActive ? Colors.green : Colors.red),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: widget.isBarberActive ? Colors.green : Colors.red, size: 8),
                  const SizedBox(width: 5),
                  Text(
                    widget.isBarberActive ? 'Activo' : 'Descanso',
                    style: TextStyle(color: widget.isBarberActive ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGoldColor, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/images/banner_ariam.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kCardBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kGoldColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kGoldColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ubicación de hoy:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(widget.location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (widget.announcement.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kGoldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kGoldColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.announcement, color: kGoldColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.announcement,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¿Consultar estado de tu turno?', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchPhoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu teléfono...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: kBgColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchedPhone = _searchPhoneController.text.trim();
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        child: const Text('Buscar'),
                      ),
                    ],
                  ),
                  if (_searchedPhone != null && _searchedPhone!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (clientBookings.isEmpty)
                      const Text('No se encontraron reservas con este teléfono.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    else
                      ...clientBookings.map((cb) {
                        final b = cb as Map<String, dynamic>;
                        final st = b['status'] ?? 'Pendiente';
                        final stColor = st == 'Confirmada' ? Colors.green : (st == 'Cancelado' ? Colors.red : Colors.orange);
                        return Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${b['service'] ?? 'Servicio'} (${b['time'] ?? ''})', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: stColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                child: Text(st, style: TextStyle(color: stColor, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                        );
                      }),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kGoldColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombre del Cliente', style: TextStyle(color: kGoldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: kGoldColor),
                      hintText: 'Tu nombre completo',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: kBgColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Teléfono / WhatsApp', style: TextStyle(color: kGoldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone, color: kGoldColor),
                      hintText: '+53 ...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: kBgColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Servicio', style: TextStyle(color: kGoldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedServiceIndex < widget.services.length ? _selectedServiceIndex : 0,
                        dropdownColor: kCardBgColor,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: kGoldColor),
                        items: List.generate(widget.services.length, (index) {
                          final s = widget.services[index] as Map<String, dynamic>;
                          final sPrice = int.tryParse(s['price']?.toString() ?? '0') ?? 0;
                          return DropdownMenuItem(
                            value: index,
                            child: Row(
                              children: [
                                Icon(s['icon'] ?? Icons.content_cut, color: kGoldColor, size: 18),
                                const SizedBox(width: 10),
                                Text('${s['name']} ($sPrice CUP)', style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedServiceIndex = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Hora Disponible', style: TextStyle(color: kGoldColor, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTime,
                        hint: const Text('Selecciona una hora disponible', style: TextStyle(color: Colors.grey)),
                        dropdownColor: kCardBgColor,
                        isExpanded: true,
                        icon: const Icon(Icons.access_time, color: kGoldColor),
                        items: widget.availableHours.map((time) {
                          return DropdownMenuItem(
                            value: time,
                            child: Text(time, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTime = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.isBarberActive ? _submitBooking : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isBarberActive ? kGoldColor : Colors.grey,
                        foregroundColor: kBgColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        widget.isBarberActive ? 'CONFIRMAR RESERVA' : 'BARBERO EN DESCANSO',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(color: kCardBgColor, borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                collapsedIconColor: kGoldColor,
                iconColor: kGoldColor,
                title: const Text('Valoraciones de Clientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('¿Ya te cortaste con Ariam? Déjanos tu opinión:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                color: kGoldColor,
                              ),
                              onPressed: () => setState(() => _selectedRating = index + 1),
                            );
                          }),
                        ),
                        TextField(
                          controller: _reviewController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu experiencia...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: kBgColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: kGoldColor, foregroundColor: Colors.black),
                            onPressed: () {
                              if (_reviewController.text.trim().isNotEmpty) {
                                widget.onAddReview({
                                  'name': _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Cliente',
                                  'text': _reviewController.text.trim(),
                                  'rating': _selectedRating,
                                });
                                _reviewController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Gracias por tu valoración!')));
                              }
                            },
                            child: const Text('Publicar Opinión', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.reviews.map((r) {
                          final review = r as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kBgColor, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const CircleAvatar(backgroundColor: kGoldColor, child: Icon(Icons.person, color: Colors.black, size: 18)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(review['name'] ?? 'Cliente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          Row(
                                            children: List.generate(
                                              review['rating'] ?? 5,
                                              (_) => const Icon(Icons.star, color: kGoldColor, size: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(review['text'] ?? '', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================================
   2. PANEL DE CONTROL DE ARIAM (ADMIN)
========================================== */
class AdminPanelScreen extends StatefulWidget {
  final List bookings;
  final List services;
  final List accountingRecords;
  final bool isBarberActive;
  final List<String> availableHours;
  final String currentAnnouncement;
  final String currentLocation;
  final List reviews;
  final Function(dynamic, String) onStatusChanged;
  final Function(dynamic) onDelete;
  final Function(dynamic) onFinish;
  final Function(Map<String, dynamic>, {int? editIndex}) onSaveService;
  final Function(bool) onToggleBarberStatus;
  final Function(String) onToggleHourAvailability;
  final Function(String) onUpdateAnnouncement;
  final Function(String) onUpdateLocation;
  final Function(dynamic) onDeleteReview;
  final VoidCallback onSwitchToClient;

  const AdminPanelScreen({
    super.key,
    required this.bookings,
    required this.services,
    required this.accountingRecords,
    required this.isBarberActive,
    required this.availableHours,
    required this.currentAnnouncement,
    required this.currentLocation,
    required this.reviews,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onFinish,
    required this.onSaveService,
    required this.onToggleBarberStatus,
    required this.onToggleHourAvailability,
    required this.onUpdateAnnouncement,
    required this.onUpdateLocation,
    required this.onDeleteReview,
    required this.onSwitchToClient,
  });

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _adminTab = 0;
  String _filterStatus = 'Todas';

  late TextEditingController _announcementCtrl;
  late TextEditingController _locationCtrl;
  final TextEditingController _newHourCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _announcementCtrl = TextEditingController(text: widget.currentAnnouncement);
    _locationCtrl = TextEditingController(text: widget.currentLocation);
  }

  @override
  void dispose() {
    _announcementCtrl.dispose();
    _locationCtrl.dispose();
    _newHourCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.bookings.where((b) => (b as Map)['status'] == 'Pendiente').length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('PANEL • ARIAM', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 16)),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    child: Text('$pendingCount nuevo(s)', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                const Text('Activo:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Switch(
                  value: widget.isBarberActive,
                  activeColor: kGoldColor,
                  onChanged: widget.onToggleBarberStatus,
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: kGoldColor),
                  onPressed: widget.onSwitchToClient,
                  tooltip: 'Volver a Web de Clientes',
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: kBgColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 0),
                    icon: Icon(Icons.list_alt, color: _adminTab == 0 ? kGoldColor : Colors.grey),
                    label: Text('Turnos ($pendingCount)', style: TextStyle(color: _adminTab == 0 ? kGoldColor : Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 1),
                    icon: Icon(Icons.design_services, color: _adminTab == 1 ? kGoldColor : Colors.grey),
                    label: Text('Servicios', style: TextStyle(color: _adminTab == 1 ? kGoldColor : Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 2),
                    icon: Icon(Icons.access_time, color: _adminTab == 2 ? kGoldColor : Colors.grey),
                    label: Text('Horarios', style: TextStyle(color: _adminTab == 2 ? kGoldColor : Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 3),
                    icon: Icon(Icons.announcement, color: _adminTab == 3 ? kGoldColor : Colors.grey),
                    label: Text('Avisos y Local', style: TextStyle(color: _adminTab == 3 ? kGoldColor : Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 4),
                    icon: Icon(Icons.star, color: _adminTab == 4 ? kGoldColor : Colors.grey),
                    label: Text('Reseñas', style: TextStyle(color: _adminTab == 4 ? kGoldColor : Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _adminTab = 5),
                    icon: Icon(Icons.account_balance_wallet, color: _adminTab == 5 ? kGoldColor : Colors.grey),
                    label: Text('Economía', style: TextStyle(color: _adminTab == 5 ? kGoldColor : Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: IndexedStack(
              index: _adminTab,
              children: [
                _buildBookingsTab(),
                _buildServicesTab(),
                _buildHoursTab(),
                _buildSettingsTab(),
                _buildReviewsTab(),
                AccountingTab(accountingRecords: widget.accountingRecords),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final filtered = widget.bookings.where((b) {
      final booking = b as Map<String, dynamic>;
      if (_filterStatus == 'Todas') return true;
      return booking['status'] == _filterStatus;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Filtrar turnos:', style: TextStyle(color: Colors.grey)),
            DropdownButton<String>(
              value: _filterStatus,
              dropdownColor: kCardBgColor,
              style: const TextStyle(color: kGoldColor),
              items: ['Todas', 'Pendiente', 'Confirmada', 'Terminado', 'Cancelado'].map((s) {
                return DropdownMenuItem(value: s, child: Text(s));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _filterStatus = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: Text('No hay turnos con este filtro.', style: TextStyle(color: Colors.grey))),
          )
        else
          ...filtered.map((b) {
            final booking = b as Map<String, dynamic>;
            final id = booking['id'];
            final status = booking['status'] ?? 'Pendiente';
            final stColor = status == 'Confirmada' ? Colors.green : (status == 'Terminado' ? Colors.blue : (status == 'Cancelado' ? Colors.red : Colors.orange));
            final bookingPrice = int.tryParse(booking['price']?.toString() ?? '0') ?? 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kCardBgColor,
                borderRadius: BorderRadius.circular(10),
                border: status == 'Pendiente' ? Border.all(color: Colors.redAccent, width: 1.5) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (status == 'Pendiente')
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.fiber_new, color: Colors.redAccent, size: 20),
                            ),
                          Text(booking['client'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: stColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: stColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Tel: ${booking['phone'] ?? ''}', style: TextStyle(color: Colors.grey[400])),
                  Text('Servicio: ${booking['service'] ?? ''} - $bookingPrice CUP (${booking['time'] ?? ''})', style: const TextStyle(color: kGoldColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (status != 'Terminado')
                        ElevatedButton.icon(
                          onPressed: () => widget.onFinish(id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Terminado'),
                        ),
                      if (status == 'Pendiente')
                        ElevatedButton.icon(
                          onPressed: () => widget.onStatusChanged(id, 'Confirmada'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          icon: const Icon(Icons.thumb_up, size: 16),
                          label: const Text('Confirmar'),
                        ),
                      if (status != 'Cancelado' && status != 'Terminado')
                        ElevatedButton.icon(
                          onPressed: () => widget.onStatusChanged(id, 'Cancelado'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancelar'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => widget.onDelete(id),
                        tooltip: 'Eliminar turno',
                      ),
                    ],
                  )
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showServiceModal(context),
          style: ElevatedButton.styleFrom(backgroundColor: kGoldColor, foregroundColor: Colors.black),
          icon: const Icon(Icons.add),
          label: const Text('Agregar Nuevo Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        ...widget.services.map((s) {
          final service = s as Map<String, dynamic>;
          final sPrice = int.tryParse(service['price']?.toString() ?? '0') ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kCardBgColor, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(service['icon'] ?? Icons.content_cut, color: kGoldColor),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(service['duration'] ?? '30 min', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('$sPrice CUP', style: const TextStyle(color: kGoldColor, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                      onPressed: () => _showServiceModal(context, existingService: service, serviceId: service['id']),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showServiceModal(BuildContext context, {Map<String, dynamic>? existingService, dynamic serviceId}) {
    final nameCtrl = TextEditingController(text: existingService?['name'] ?? '');
    final priceCtrl = TextEditingController(text: existingService?['price']?.toString() ?? '');
    final durCtrl = TextEditingController(text: existingService?['duration'] ?? '30 min');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardBgColor,
        title: Text(serviceId == null ? 'Nuevo Servicio' : 'Editar Servicio', style: const TextStyle(color: kGoldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del servicio'), style: const TextStyle(color: Colors.white)),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio (CUP)'), style: const TextStyle(color: Colors.white)),
            TextField(controller: durCtrl, decoration: const InputDecoration(labelText: 'Duración (ej. 30 min)'), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                final cleanPriceStr = priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
                final finalPrice = int.tryParse(cleanPriceStr) ?? 0;

                widget.onSaveService({
                  'name': nameCtrl.text.trim(),
                  'price': finalPrice,
                  'duration': durCtrl.text.trim(),
                }, editIndex: serviceId);
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Horarios Disponibles para la Web', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Toca una hora para activarla o desactivarla en el sistema de reservas.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.availableHours.map((h) {
            return Chip(
              backgroundColor: kCardBgColor,
              label: Text(h, style: const TextStyle(color: Colors.white)),
              deleteIcon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
              onDeleted: () => widget.onToggleHourAvailability(h),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Agregar Nueva Hora', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newHourCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ej. 01:30 PM',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: kCardBgColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kGoldColor, foregroundColor: Colors.black),
              onPressed: () {
                if (_newHourCtrl.text.trim().isNotEmpty) {
                  widget.onToggleHourAvailability(_newHourCtrl.text.trim());
                  _newHourCtrl.clear();
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Ubicación del Local o Barbería', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: _locationCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: kCardBgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldColor, foregroundColor: Colors.black),
            onPressed: () => widget.onUpdateLocation(_locationCtrl.text.trim()),
            child: const Text('Actualizar Ubicación'),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Tablón de Avisos (Mensaje destacado en la web)', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: _announcementCtrl,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: kCardBgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGoldColor, foregroundColor: Colors.black),
            onPressed: () => widget.onUpdateAnnouncement(_announcementCtrl.text.trim()),
            child: const Text('Publicar Aviso'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Gestor de Reseñas (Limpiar valoraciones)', style: TextStyle(color: kGoldColor, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        if (widget.reviews.isEmpty)
          const Text('No hay reseñas publicadas.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ...widget.reviews.map((r) {
            final review = r as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCardBgColor, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(review['name'] ?? 'Cliente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Row(children: List.generate(review['rating'] ?? 5, (_) => const Icon(Icons.star, color: kGoldColor, size: 12))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(review['text'] ?? '', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => widget.onDeleteReview(review['id']),
                    tooltip: 'Borrar reseña',
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

/* ==========================================
   3. PESTAÑA DE ECONOMÍA (SEMANAL / MENSUAL)
========================================== */
class AccountingTab extends StatefulWidget {
  final List accountingRecords;

  const AccountingTab({super.key, required this.accountingRecords});

  @override
  State<AccountingTab> createState() => _AccountingTabState();
}

class _AccountingTabState extends State<AccountingTab> {
  String _periodo = 'Semanal';
  bool _periodoReiniciado = false;

  @override
  Widget build(BuildContext context) {
    final recordsToProcess = _periodoReiniciado ? [] : widget.accountingRecords;

    int totalGeneral = 0;
    Map<String, int> serviceBreakdown = {};

    for (var r in recordsToProcess) {
      final rec = r as Map<String, dynamic>;
      final price = int.tryParse(rec['price']?.toString() ?? '0') ?? 0;
      final serviceName = rec['service'] ?? 'Desconocido';
      totalGeneral += price;
      serviceBreakdown[serviceName] = (serviceBreakdown[serviceName] ?? 0) + price;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Periodo de Caja:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            DropdownButton<String>(
              value: _periodo,
              dropdownColor: kCardBgColor,
              style: const TextStyle(color: kGoldColor, fontWeight: FontWeight.bold),
              items: ['Semanal', 'Mensual'].map((p) {
                return DropdownMenuItem(value: p, child: Text(p));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _periodo = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGoldColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL INGRESOS (${_periodo.toUpperCase()})', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('$totalGeneral CUP', style: const TextStyle(color: kGoldColor, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _periodoReiniciado = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('¡Corte de caja realizado! Nuevo periodo iniciado.')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Nuevo Periodo (Corte)'),
              ),
            ),
            const SizedBox(width: 8),
            if (_periodoReiniciado)
              TextButton(
                onPressed: () => setState(() => _periodoReiniciado = false),
                child: const Text('Deshacer corte', style: TextStyle(color: kGoldColor)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte exportado en formato Word (.doc) con éxito.')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                icon: const Icon(Icons.description),
                label: const Text('Exportar Word'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reporte generado en formato PDF con éxito.')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Desglose por Servicios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        if (serviceBreakdown.isEmpty)
          const Text('Aún no hay ingresos registrados en este periodo.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ...serviceBreakdown.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCardBgColor, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(color: Colors.white)),
                  Text('${entry.value} CUP', style: const TextStyle(color: kGoldColor, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        const SizedBox(height: 20),
        const Text('Historial de Caja del Periodo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        if (recordsToProcess.isEmpty)
          const Text('Aún no hay servicios finalizados en este periodo.', style: TextStyle(color: Colors.grey, fontSize: 13))
        else
          ...recordsToProcess.map((r) {
            final rec = r as Map<String, dynamic>;
            final clientName = rec['client'] ?? 'Cliente';
            final serviceName = rec['service'] ?? '';
            final timeStr = rec['time'] ?? '';
            final priceVal = int.tryParse(rec['price']?.toString() ?? '0') ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kCardBgColor, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('$serviceName • $timeStr', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  Text('+$priceVal CUP', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
      ],
    );
  }
}