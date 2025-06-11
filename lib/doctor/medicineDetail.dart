// medicineDetail.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineEntry {
  String form;
  String name;
  int? medicineId; // Added to store the actual medicine ID from database
  String dosage; // Added dosage field
  String beforeAfterBreakfast;
  String beforeAfterLunch;
  String beforeAfterDinner;
  DateTime? startDate;
  DateTime? endDate;
  TextEditingController nameController;
  TextEditingController dosageController; // Added dosage controller

  MedicineEntry({
    this.form = "Tablet",
    this.name = "",
    this.medicineId,
    this.dosage = "",
    this.beforeAfterBreakfast = "No",
    this.beforeAfterLunch = "No",
    this.beforeAfterDinner = "No",
    this.startDate,
    this.endDate,
  })  : nameController = TextEditingController(text: name),
        dosageController = TextEditingController(text: dosage);

  // Create MedicineEntry from JSON data
  factory MedicineEntry.fromJson(Map<String, dynamic> json) {
    return MedicineEntry(
      form: json['type'] ?? "Tablet",
      name: json['name'] ?? "",
      medicineId: json['medicine_id'],
      dosage: json['dosage'] ?? "",
      beforeAfterBreakfast: json['breakfast'] ?? "No",
      beforeAfterLunch: json['launch'] ?? "No",
      beforeAfterDinner: json['dinner'] ?? "No",
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': form,
      'name': nameController.text,
      'medicine_id': medicineId,
      'dosage': dosageController.text,
      'breakfast': beforeAfterBreakfast,
      'launch': beforeAfterLunch,
      'dinner': beforeAfterDinner,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
  }
}

class MedicineEntryWidget extends StatefulWidget {
  final MedicineEntry entry;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback onDateRangeSelect;
  final VoidCallback onUpdate;

  const MedicineEntryWidget({
    Key? key,
    required this.entry,
    required this.index,
    this.onRemove,
    required this.onDateRangeSelect,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _MedicineEntryWidgetState createState() => _MedicineEntryWidgetState();
}

class _MedicineEntryWidgetState extends State<MedicineEntryWidget> {
  List<Map<String, dynamic>> _availableMedicines = [];
  List<String> _availableForms = [];
  bool _isLoadingMedicines = false;

  // Dosage suggestions for different forms
  static const Map<String, List<String>> _dosageSuggestions = {
    "Syrup": ["Half a spoon", "One spoon", "Two spoons"],
    "Tablet": ["Half tablet", "One tablet", "Two tablets", "Three tablets"],
    "Capsule": ["One capsule", "Two capsules", "Three capsules"],
    "Drops": [
      "One drop",
      "Two drops",
      "Three drops",
      "Four drops",
      "Five drops"
    ],
    "Patch": ["One patch", "Two patches"],
  };

  // Forms that don't have dosage suggestions
  static const List<String> _formsWithoutDosage = [
    "Injection",
    "Inhaler",
    "Gel",
    "Cream",
    "Ointment"
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableForms();
  }

  Future<void> _loadAvailableForms() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final response = await supabase
          .from('Medicines')
          .select('form')
          .order('form', ascending: true);

      final forms = response
          .map<String>((item) => item['form'].toString())
          .toSet()
          .toList();

      setState(() {
        _availableForms = forms;
        if (_availableForms.isNotEmpty &&
            !_availableForms.contains(widget.entry.form)) {
          widget.entry.form = _availableForms.first;
        }
      });

      // Load medicines for current form
      if (widget.entry.form.isNotEmpty) {
        await _loadMedicinesByForm(widget.entry.form);
      }
    } catch (e) {
      print('Error loading forms: $e');
      // Fallback to default forms
      setState(() {
        _availableForms = [
          "Syrup",
          "Tablet",
          "Capsule",
          "Drops",
          "Cream",
          "Gel",
          "Ointment",
          "Inhaler",
          "Patch",
          "Injection",
        ];
      });
    }
  }

  Future<void> _loadMedicinesByForm(String form) async {
    setState(() {
      _isLoadingMedicines = true;
    });

    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final response = await supabase
          .from('Medicines')
          .select('medicine_id, name, form, description')
          .eq('form', form)
          .order('name', ascending: true);

      setState(() {
        _availableMedicines = List<Map<String, dynamic>>.from(response);
        _isLoadingMedicines = false;
      });
    } catch (e) {
      print('Error loading medicines: $e');
      setState(() {
        _availableMedicines = [];
        _isLoadingMedicines = false;
      });
    }
  }

  void _onFormChanged(String? newForm) {
    if (newForm != null && newForm != widget.entry.form) {
      widget.entry.form = newForm;
      widget.entry.nameController.clear();
      widget.entry.dosageController.clear(); // Clear dosage when form changes
      widget.entry.medicineId = null;
      _loadMedicinesByForm(newForm);
      widget.onUpdate();
    }
  }

  void _onMedicineSelected(Map<String, dynamic> medicine) {
    widget.entry.nameController.text = medicine['name'];
    widget.entry.medicineId = medicine['medicine_id'];
    widget.onUpdate();
  }

  bool _shouldShowDosageField() {
    return !_formsWithoutDosage.contains(widget.entry.form);
  }

  List<String> _getDosageSuggestions() {
    return _dosageSuggestions[widget.entry.form] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medicine ${widget.index + 1}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onRemove,
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Form dropdown
            DropdownButtonFormField<String>(
              value: _availableForms.contains(widget.entry.form)
                  ? widget.entry.form
                  : (_availableForms.isNotEmpty ? _availableForms.first : null),
              decoration: const InputDecoration(
                labelText: "Form",
                border: OutlineInputBorder(),
              ),
              items: _availableForms.map((String form) {
                return DropdownMenuItem<String>(
                  value: form,
                  child: Text(form),
                );
              }).toList(),
              onChanged: _onFormChanged,
            ),
            const SizedBox(height: 16),

            // Medicine name autocomplete
            if (_isLoadingMedicines)
              const Center(child: CircularProgressIndicator())
            else
              Autocomplete<Map<String, dynamic>>(
                initialValue:
                    TextEditingValue(text: widget.entry.nameController.text),
                displayStringForOption: (medicine) => medicine['name'],
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _availableMedicines;
                  }
                  return _availableMedicines.where((medicine) =>
                      medicine['name']
                          .toString()
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: _onMedicineSelected,
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int index) {
                            final medicine = options.elementAt(index);
                            return ListTile(
                              title: Text(medicine['name']),
                              subtitle: medicine['description'] != null &&
                                      medicine['description']
                                          .toString()
                                          .isNotEmpty
                                  ? Text(
                                      medicine['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                onSelected(medicine);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onSubmitted) {
                  // Keep the controller in sync
                  if (controller.text != widget.entry.nameController.text) {
                    widget.entry.nameController = controller;
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Name of Medicine",
                      border: OutlineInputBorder(),
                      hintText: "Search and select medicine...",
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Dosage field (only show for applicable forms)
            if (_shouldShowDosageField()) ...[
              if (_getDosageSuggestions().isNotEmpty)
                Autocomplete<String>(
                  initialValue: TextEditingValue(
                      text: widget.entry.dosageController.text),
                  displayStringForOption: (option) => option,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final suggestions = _getDosageSuggestions();
                    if (textEditingValue.text.isEmpty) {
                      return suggestions;
                    }
                    return suggestions.where((suggestion) => suggestion
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    widget.entry.dosageController.text = selection;
                    widget.onUpdate();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onSubmitted) {
                    // Keep the controller in sync
                    if (controller.text != widget.entry.dosageController.text) {
                      widget.entry.dosageController = controller;
                    }
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: "Dosage",
                        border: OutlineInputBorder(),
                        hintText: "Enter or select dosage...",
                      ),
                    );
                  },
                )
              else
                TextField(
                  controller: widget.entry.dosageController,
                  decoration: const InputDecoration(
                    labelText: "Dosage",
                    border: OutlineInputBorder(),
                    hintText: "Enter dosage...",
                  ),
                  onChanged: (value) => widget.onUpdate(),
                ),
              const SizedBox(height: 16),
            ],

            _buildRadioGroup(
              "Breakfast",
              widget.entry.beforeAfterBreakfast,
              (value) {
                widget.entry.beforeAfterBreakfast = value!;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 16),

            _buildRadioGroup(
              "Lunch",
              widget.entry.beforeAfterLunch,
              (value) {
                widget.entry.beforeAfterLunch = value!;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 16),

            _buildRadioGroup(
              "Dinner",
              widget.entry.beforeAfterDinner,
              (value) {
                widget.entry.beforeAfterDinner = value!;
                widget.onUpdate();
              },
            ),
            const SizedBox(height: 16),

            // Date range selection
            Row(
              children: [
                ElevatedButton(
                  onPressed: widget.onDateRangeSelect,
                  child: const Text("Select Period"),
                ),
                const SizedBox(width: 16),
                if (widget.entry.startDate != null &&
                    widget.entry.endDate != null)
                  Expanded(
                    child: Text(
                      "${DateFormat('dd/MM/yyyy').format(widget.entry.startDate!)} - ${DateFormat('dd/MM/yyyy').format(widget.entry.endDate!)}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioGroup(
      String label, String selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
          children: [
            Radio<String>(
              value: "No",
              groupValue: selectedValue,
              onChanged: onChanged,
            ),
            const Text("No"),
            const SizedBox(width: 16),
            Radio<String>(
              value: "Before",
              groupValue: selectedValue,
              onChanged: onChanged,
            ),
            const Text("Before"),
            const SizedBox(width: 16),
            Radio<String>(
              value: "After",
              groupValue: selectedValue,
              onChanged: onChanged,
            ),
            const Text("After"),
          ],
        ),
      ],
    );
  }
}
