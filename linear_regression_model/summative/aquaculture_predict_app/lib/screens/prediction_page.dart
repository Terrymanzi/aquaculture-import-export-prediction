import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _yearController = TextEditingController();
  late AnimationController _buttonController;

  final String apiUrl =
      'https://aquaculture-import-export-prediction.onrender.com';
  bool _isLoading = false;
  Map<String, dynamic>? _predictionResult;
  String? _errorMessage;

  final List<String> _countries = [
    'Algeria',
    'Angola',
    'Benin',
    'Botswana',
    'Burkina Faso',
    'Burundi',
    'Cameroon',
    'Cape Verde',
    'Central African Republic',
    'Chad',
    'Comoros',
    'Congo',
    'Djibouti',
    'Egypt',
    'Equatorial Guinea',
    'Eritrea',
    'Ethiopia',
    'Gabon',
    'Gambia',
    'Ghana',
    'Guinea',
    'Guinea-Bissau',
    'Ivory Coast',
    'Kenya',
    'Lesotho',
    'Liberia',
    'Libya',
    'Madagascar',
    'Malawi',
    'Mali',
    'Mauritania',
    'Mauritius',
    'Morocco',
    'Mozambique',
    'Namibia',
    'Niger',
    'Nigeria',
    'Rwanda',
    'Senegal',
    'Seychelles',
    'Sierra Leone',
    'Somalia',
    'South Africa',
    'Sudan',
    'Swaziland',
    'Tanzania',
    'Togo',
    'Tunisia',
    'Uganda',
    'Zambia',
    'Zimbabwe'
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _countryController.dispose();
    _yearController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _makePrediction() async {
    if (!_formKey.currentState!.validate()) return;

    _buttonController.forward().then((_) => _buttonController.reverse());

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _predictionResult = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/predict'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'country': _countryController.text,
          'year': int.parse(_yearController.text),
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _predictionResult = json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        setState(() => _errorMessage = error['detail'] ?? 'Prediction failed');
      }
    } catch (e) {
      setState(
          () => _errorMessage = 'Network error: Please check your connection');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.oceanGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputCard()
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: 0.3),
                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          _buildErrorCard()
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .shake(),
                        if (_predictionResult != null)
                          _buildResultCard()
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .slideY(begin: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Make Prediction',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.input, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Text(
                  'Prediction Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCountryAutocomplete(),
            const SizedBox(height: 20),
            _buildYearInput(),
            const SizedBox(height: 32),
            _buildPredictButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _countries.where((country) => country
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) => _countryController.text = selection,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              width: MediaQuery.of(context).size.width - 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.lightGrey,
                            width: index == options.length - 1 ? 0 : 1,
                          ),
                        ),
                      ),
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        _countryController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Country',
            hintText: 'e.g., Egypt, Nigeria',
            prefixIcon:
                const Icon(Icons.location_on, color: AppTheme.primaryBlue),
            labelStyle: GoogleFonts.poppins(color: AppTheme.grey),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a country name' : null,
        );
      },
    );
  }

  Widget _buildYearInput() {
    return TextFormField(
      controller: _yearController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Year',
        hintText: 'e.g., 2025',
        prefixIcon:
            const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
        labelStyle: GoogleFonts.poppins(color: AppTheme.grey),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Please enter a year';
        final year = int.tryParse(value!);
        if (year == null) return 'Please enter a valid year';
        if (year < 2000 || year > 2050) {
          return 'Year must be between 2000 and 2050';
        }
        return null;
      },
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_buttonController.value * 0.05),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _makePrediction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                disabledBackgroundColor: AppTheme.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.analytics, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Make Prediction',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                color: Colors.red.shade700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.teal.shade50],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.green.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.analytics, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                Text(
                  'Prediction Results',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResultRow('Country', _predictionResult!['country']),
            _buildResultRow('Year', _predictionResult!['year'].toString()),
            const Divider(height: 32),
            _buildResultRow(
              'Export Volume',
              '${_predictionResult!['export_volume'].toStringAsFixed(2)} ${_predictionResult!['unit']}',
              isHighlight: true,
            ),
            _buildResultRow(
              'Import Volume',
              '${_predictionResult!['import_volume'].toStringAsFixed(2)} ${_predictionResult!['unit']}',
              isHighlight: true,
            ),
            const Divider(height: 32),
            _buildResultRow(
              'Confidence Level',
              _predictionResult!['confidence_level'].toString().toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppTheme.primaryBlue : null,
              fontSize: isHighlight ? 16 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
