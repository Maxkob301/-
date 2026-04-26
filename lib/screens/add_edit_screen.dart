import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/geocoding_service.dart';
import 'map_picker_screen.dart';

class AddEditScreen extends StatefulWidget {
  final LostFoundItem? item;

  const AddEditScreen({super.key, this.item});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final GeocodingService _geocodingService = GeocodingService();
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _addressController;

  late DateTime _selectedDate;
  late String _selectedType;
  late String _selectedCategory;
  late String _selectedDistrict;

  double? _selectedLatitude;
  double? _selectedLongitude;

  XFile? _selectedImage;
  String? _currentImageUrl;

  bool _isSaving = false;
  bool _hideLocation = true;
  bool _isLoadingAddress = false;
  bool _isUploadingImage = false;

  final List<String> _categories = [
    'Документы',
    'Электроника',
    'Одежда',
    'Сумки',
    'Ключи',
    'Другое',
  ];

  final List<String> _districts = [
    'Центральный',
    'Северный',
    'Южный',
    'Западный',
    'Восточный',
    'Другой',
  ];

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.item?.description ?? '');
    _locationController =
        TextEditingController(text: widget.item?.location ?? '');
    _addressController =
        TextEditingController(text: widget.item?.addressText ?? '');

    _selectedDate = widget.item?.date ?? DateTime.now();
    _selectedType = widget.item?.type ?? 'lost';

    _selectedCategory = _categories.contains(widget.item?.category)
        ? widget.item!.category
        : 'Другое';

    _selectedDistrict = _districts.contains(widget.item?.district)
        ? widget.item!.district
        : 'Другой';

    _hideLocation = widget.item?.isLocationHidden ?? true;
    _selectedLatitude = widget.item?.latitude;
    _selectedLongitude = widget.item?.longitude;

    _currentImageUrl = widget.item?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? selectedPoint = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLatitude: _selectedLatitude,
          initialLongitude: _selectedLongitude,
        ),
      ),
    );

    if (!mounted || selectedPoint == null) return;

    setState(() {
      _selectedLatitude = selectedPoint.latitude;
      _selectedLongitude = selectedPoint.longitude;
      _isLoadingAddress = true;
    });

    try {
      final result = await _geocodingService.reverseGeocode(
        latitude: selectedPoint.latitude,
        longitude: selectedPoint.longitude,
      );

      if (!mounted) return;

      setState(() {
        if (result != null) {
          _addressController.text = result.addressText;

          if (_districts.contains(result.district)) {
            _selectedDistrict = result.district;
          } else {
            _selectedDistrict = 'Другой';
          }
        }

        _isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAddress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось получить адрес: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _save(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving || _isUploadingImage) return;

    setState(() => _isSaving = true);

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final currentUser = Provider.of<AuthProvider>(context, listen: false).user;

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final location = _locationController.text.trim();
      final addressText = _addressController.text.trim();

      String? imageUrl = _currentImageUrl;

      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);

        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);

        if (!mounted) return;

        setState(() {
          _isUploadingImage = false;
          _currentImageUrl = imageUrl;
        });
      }

      if (widget.item == null) {
        final newItem = LostFoundItem(
          id: '',
          title: title,
          description: description,
          location: location,
          date: _selectedDate,
          type: _selectedType,
          imageUrl: imageUrl,
          userId: userId,
          status: 'active',
          createdAt: DateTime.now(),
          authorEmail: currentUser?.email ?? '',
          category: _selectedCategory,
          district: _selectedDistrict,
          acceptedHelperId: '',
          isLocationHidden: _hideLocation,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          addressText: addressText,
        );

        await itemProvider.addItem(newItem, userId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Объявление создано')),
        );
        Navigator.pop(context, true);
      } else {
        await itemProvider.updateItem(widget.item!.id, {
          'title': title,
          'description': description,
          'location': location,
          'date': Timestamp.fromDate(_selectedDate),
          'type': _selectedType,
          'category': _selectedCategory,
          'district': _selectedDistrict,
          'isLocationHidden': _hideLocation,
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'addressText': addressText,
          'imageUrl': imageUrl,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изменения сохранены')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _buildImageBlock() {
    final hasCurrentImage =
        _currentImageUrl != null && _currentImageUrl!.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (_isSaving || _isUploadingImage) ? null : _pickImage,
            icon: const Icon(Icons.image),
            label: Text(
              _selectedImage != null || hasCurrentImage
                  ? 'Фото выбрано'
                  : 'Добавить фото вещи',
            ),
          ),
        ),
        if (hasCurrentImage) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _currentImageUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Text('Не удалось загрузить фото'),
                );
              },
            ),
          ),
        ],
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          const Text(
            'Новое фото выбрано. Оно загрузится после сохранения.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;

    final isBusy = _isSaving || _isUploadingImage;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null
              ? 'Добавить объявление'
              : 'Редактировать объявление',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Описание места',
                  hintText: 'Например: около входа, рядом с аудиторией и т.д.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите описание места';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: isBusy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedDistrict,
                decoration: const InputDecoration(
                  labelText: 'Район',
                ),
                items: _districts
                    .map(
                      (district) => DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      ),
                    )
                    .toList(),
                onChanged: isBusy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedDistrict = value);
                        }
                      },
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Скрыть район, адрес и точную локацию до принятия заявки',
                ),
                subtitle: const Text(
                  'Другие пользователи увидят эти данные только после одобрения отклика',
                ),
                value: _hideLocation,
                activeColor: Colors.black,
                onChanged: isBusy
                    ? null
                    : (value) {
                        setState(() {
                          _hideLocation = value ?? true;
                        });
                      },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isBusy || _isLoadingAddress ? null : _openMapPicker,
                  icon: const Icon(Icons.map),
                  label: Text(
                    _selectedLatitude != null && _selectedLongitude != null
                        ? 'Точка на карте выбрана'
                        : 'Выбрать место на карте',
                  ),
                ),
              ),

              if (_selectedLatitude != null && _selectedLongitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Координаты: ${_selectedLatitude!.toStringAsFixed(5)}, '
                  '${_selectedLongitude!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Адрес по карте',
                  hintText: 'Появится после выбора точки',
                  suffixIcon: _isLoadingAddress
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.place),
                ),
              ),

              const SizedBox(height: 16),

              _buildImageBlock(),

              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Дата: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: isBusy ? null : _pickDate,
              ),

              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Тип объявления:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Потеряно'),
                      value: 'lost',
                      groupValue: _selectedType,
                      activeColor: Colors.black,
                      onChanged: isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Найдено'),
                      value: 'found',
                      groupValue: _selectedType,
                      activeColor: Colors.black,
                      onChanged: isBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _selectedType = value);
                              }
                            },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isBusy || currentUser == null) ? null : () => _save(currentUser.uid),
                  child: isBusy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.item == null ? 'Создать' : 'Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}