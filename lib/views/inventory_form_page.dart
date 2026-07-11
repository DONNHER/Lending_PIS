import 'package:flutter/material.dart';
import '../models/consignment_daily_inventory.dart';

class InventoryFormPage extends StatefulWidget {
  final String productId;
  final ConsignmentDailyInventoryModel? inventory;

  const InventoryFormPage({super.key, required this.productId, this.inventory});

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late int _received;
  late int _sold;
  late int _returned;

  @override
  void initState() {
    super.initState();
    _received = widget.inventory?.received ?? 0;
    _sold = widget.inventory?.sold ?? 0;
    _returned = widget.inventory?.returned ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory == null ? 'Add Inventory Log' : 'Edit Inventory Log'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _received.toString(),
              decoration: const InputDecoration(labelText: 'Received'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _received = int.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _sold.toString(),
              decoration: const InputDecoration(labelText: 'Sold'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _sold = int.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _returned.toString(),
              decoration: const InputDecoration(labelText: 'Returned'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _returned = int.tryParse(v ?? '0') ?? 0,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save Log'),
            ),
          ],
        ),
      ),
    );
  }
}
