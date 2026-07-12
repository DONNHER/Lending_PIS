import 'package:flutter/material.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import '../app_theme.dart';

class AddressSelectorPage extends StatefulWidget {
  const AddressSelectorPage({super.key});

  @override
  State<AddressSelectorPage> createState() => _AddressSelectorPageState();
}

class _AddressSelectorPageState extends State<AddressSelectorPage> {
  // Using dynamic for selected items to remain version-agnostic
  dynamic selectedRegion;
  dynamic selectedProvince;
  dynamic selectedMunicipality;
  dynamic selectedBarangay;

  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _houseNumberController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Safely extracts a name from the location object or string
  String _getName(dynamic item) {
    if (item == null) return '';
    if (item is String) return item;
    try {
      return item.name.toString();
    } catch (_) {
      return item.toString();
    }
  }

  /// Safely gets the list of provinces from the selected region
  List<Province> _getProvinces() {
    if (selectedRegion == null) return [];
    try {
      return List<Province>.from(selectedRegion.provinces ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Safely gets the list of municipalities from the selected province
  List<Municipality> _getMunicipalities() {
    if (selectedProvince == null) return [];
    try {
      return List<Municipality>.from(selectedProvince.municipalities ?? []);
    } catch (_) {
      return [];
    }
  }

  /// Safely gets the list of barangays from the selected municipality
  List<String> _getBarangays() {
    if (selectedMunicipality == null) return [];
    try {
      return List<String>.from(selectedMunicipality.barangays ?? []);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Select Complete Address',
            style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Philippine Address Selection',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 24),

                  // 1. REGION
                  _buildLabel('Region'),
                  PhilippineRegionDropdownView(
                    value: selectedRegion,
                    onChanged: (dynamic value) {
                      setState(() {
                        if (selectedRegion != value) {
                          selectedProvince = null;
                          selectedMunicipality = null;
                          selectedBarangay = null;
                        }
                        selectedRegion = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. PROVINCE
                  _buildLabel('Province'),
                  PhilippineProvinceDropdownView(
                    provinces: _getProvinces(),
                    value: selectedProvince,
                    onChanged: (dynamic value) {
                      setState(() {
                        if (selectedProvince != value) {
                          selectedMunicipality = null;
                          selectedBarangay = null;
                        }
                        selectedProvince = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. CITY / MUNICIPALITY
                  _buildLabel('City / Municipality'),
                  PhilippineMunicipalityDropdownView(
                    municipalities: _getMunicipalities(),
                    value: selectedMunicipality,
                    onChanged: (dynamic value) {
                      setState(() {
                        if (selectedMunicipality != value) {
                          selectedBarangay = null;
                        }
                        selectedMunicipality = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. BARANGAY
                  _buildLabel('Barangay'),
                  PhilippineBarangayDropdownView(
                    barangays: _getBarangays(),
                    value: selectedBarangay,
                    onChanged: (dynamic value) {
                      setState(() => selectedBarangay = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. HOUSE NUMBER & STREET
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('House/Unit No.'),
                            TextFormField(
                              controller: _houseNumberController,
                              decoration: _inputDecoration('e.g. Blk 2 Lot 4'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Street Name'),
                            TextFormField(
                              controller: _streetController,
                              decoration: _inputDecoration('e.g. Rizal St.'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          selectedBarangay != null) {
                        
                        String bName = _getName(selectedBarangay);
                        String mName = _getName(selectedMunicipality);
                        String pName = _getName(selectedProvince);

                        String fullAddress =
                            "${_houseNumberController.text.trim()}, ${_streetController.text.trim()}, Brgy. $bName, $mName, $pName";
                        
                        Navigator.pop(context, fullAddress);
                      } else if (selectedBarangay == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please select a complete address')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save and Use Address',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)),
    );
  }
}
