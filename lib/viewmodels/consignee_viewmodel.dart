import 'package:flutter/foundation.dart';
import '../models/consignee_model.dart';
import '../repositories/consignee_repository.dart';
import '../repositories/storage_repository.dart';

// UI states for clean state management
enum ViewState { idle, loading, error }

class ConsigneeViewModel extends ChangeNotifier {
  final ConsigneeRepository _repository;
  final StorageRepository _storageRepository;

  // ─── State ────────────────────────────────────────────────────────────
  ViewState _state = ViewState.idle;
  List<ConsigneeModel> _consignees = [];
  String? _errorMessage;
  String _searchQuery = '';
  bool _isInitialized = false; // 🚀 Caching flag

  // ─── Constructors ─────────────────────────────────────────────────────
  ConsigneeViewModel({
    required ConsigneeRepository repository,
    required StorageRepository storageRepository,
  })  : _repository = repository,
        _storageRepository = storageRepository;

  // ─── Getters ──────────────────────────────────────────────────────────
  ViewState get state => _state;
  bool get isInitialized => _isInitialized; // 🚀 Getter for initialized status
  List<ConsigneeModel> get consignees => _searchQuery.isEmpty
      ? _consignees
      : _consignees.where((c) {
          final q = _searchQuery.toLowerCase();
          return c.fullName.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.address.toLowerCase().contains(q);
        }).toList();
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  // ─── Public Methods ────────────────────────────────────────────────────

  /// Load all consignees from database
  Future<void> loadConsignees({bool forceRefresh = false}) async {
    // 🚀 Avoid redundant loading unless forced
    if (_isInitialized && !forceRefresh && _consignees.isNotEmpty) return;

    _state = ViewState.loading;
    notifyListeners();

    try {
      _consignees = await _repository.getAll();
      _isInitialized = true;
      _state = ViewState.idle;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Update search query (filters locally)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Add a new consignee
  Future<bool> addConsignee({
    required String fullName,
    required String phone,
    required String address,
    List<int>? healthCardBytes,
    List<int>? foodHandlerCardBytes,
    String? healthCardFileName,
    String? foodHandlerCardFileName,
  }) async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      String? healthCardUrl;
      String? foodHandlerCardUrl;

      if (healthCardBytes != null && healthCardFileName != null) {
        healthCardUrl = await _storageRepository.uploadFile(
          fileBytes: healthCardBytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$healthCardFileName',
          folder: 'health-cards',
        );
      }

      if (foodHandlerCardBytes != null && foodHandlerCardFileName != null) {
        foodHandlerCardUrl = await _storageRepository.uploadFile(
          fileBytes: foodHandlerCardBytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$foodHandlerCardFileName',
          folder: 'food-handler-cards',
        );
      }

      final consignee = ConsigneeModel(
        id: '', 
        fullName: fullName,
        phone: phone,
        address: address,
        healthCardUrl: healthCardUrl,
        foodHandlerCardUrl: foodHandlerCardUrl,
      );

      await _repository.add(consignee);
      await loadConsignees(forceRefresh: true); // Force refresh to show new item
      return true;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update existing consignee
  Future<bool> updateConsignee({
    required String id,
    required String fullName,
    required String phone,
    required String address,
    List<int>? healthCardBytes,
    List<int>? foodHandlerCardBytes,
    String? healthCardFileName,
    String? foodHandlerCardFileName,
  }) async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      final existing = _consignees.firstWhere((c) => c.id == id);
      String? healthCardUrl = existing.healthCardUrl;
      String? foodHandlerCardUrl = existing.foodHandlerCardUrl;

      if (healthCardBytes != null && healthCardFileName != null) {
        if (existing.healthCardUrl != null) {
          await _storageRepository.deleteFile(existing.healthCardUrl!);
        }
        healthCardUrl = await _storageRepository.uploadFile(
          fileBytes: healthCardBytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$healthCardFileName',
          folder: 'health-cards',
        );
      }

      if (foodHandlerCardBytes != null && foodHandlerCardFileName != null) {
        if (existing.foodHandlerCardUrl != null) {
          await _storageRepository.deleteFile(existing.foodHandlerCardUrl!);
        }
        foodHandlerCardUrl = await _storageRepository.uploadFile(
          fileBytes: foodHandlerCardBytes,
          fileName: '${DateTime.now().millisecondsSinceEpoch}_$foodHandlerCardFileName',
          folder: 'food-handler-cards',
        );
      }

      final updated = ConsigneeModel(
        id: id,
        fullName: fullName,
        phone: phone,
        address: address,
        healthCardUrl: healthCardUrl,
        foodHandlerCardUrl: foodHandlerCardUrl,
      );

      await _repository.update(updated);
      await loadConsignees(forceRefresh: true);
      return true;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete consignee
  Future<bool> deleteConsignee(String id) async {
    _state = ViewState.loading;
    notifyListeners();

    try {
      final consignee = _consignees.firstWhere((c) => c.id == id);

      if (consignee.healthCardUrl != null) {
        await _storageRepository.deleteFile(consignee.healthCardUrl!);
      }
      if (consignee.foodHandlerCardUrl != null) {
        await _storageRepository.deleteFile(consignee.foodHandlerCardUrl!);
      }

      await _repository.delete(id);
      await loadConsignees(forceRefresh: true);
      return true;
    } catch (e) {
      _state = ViewState.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isInitialized = false;
    _consignees = [];
    _state = ViewState.idle;
    notifyListeners();
  }

  void clearError() {
    _state = ViewState.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
