import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../../models/athlete.dart';

/// CSV parsing result
class CsvParseResult {
  final List<Athlete> athletes;
  final List<String> errors;
  final List<String> warnings;
  final int totalRows;
  final int validRows;

  CsvParseResult({
    required this.athletes,
    required this.errors,
    required this.warnings,
    required this.totalRows,
    required this.validRows,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isSuccess => errors.isEmpty && validRows > 0;
}

/// Service for handling CSV file operations for athlete data
class CsvService {
  static CsvService? _instance;
  static CsvService get instance => _instance ??= CsvService._internal();
  
  CsvService._internal();

  /// Required CSV column headers for athlete import
  static const List<String> _requiredHeaders = [
    'name',
    'sport',
    'is_para_athlete',
    'dob',
    'place_of_birth',
  ];

  /// Optional CSV column headers
  static const List<String> _optionalHeaders = [
    'education',
    'image_url',
  ];

  /// All supported headers (required + optional)
  static const List<String> _allHeaders = [
    ..._requiredHeaders,
    ..._optionalHeaders,
  ];

  /// Parse CSV file bytes and convert to Athlete objects
  Future<CsvParseResult> parseCsvFile(Uint8List csvBytes) async {
    try {
      // Convert bytes to string
      final csvString = utf8.decode(csvBytes);
      
      // Parse CSV
      final csvData = const CsvToListConverter().convert(csvString);
      
      if (csvData.isEmpty) {
        return CsvParseResult(
          athletes: [],
          errors: ['CSV file is empty'],
          warnings: [],
          totalRows: 0,
          validRows: 0,
        );
      }

      // Extract headers and validate
      final headers = csvData.first.map((h) => h.toString().toLowerCase().trim()).toList();
      final validationResult = _validateHeaders(headers);
      
      if (validationResult.isNotEmpty) {
        return CsvParseResult(
          athletes: [],
          errors: validationResult,
          warnings: [],
          totalRows: csvData.length - 1,
          validRows: 0,
        );
      }

      // Parse data rows
      final athletes = <Athlete>[];
      final errors = <String>[];
      final warnings = <String>[];
      
      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        final rowNumber = i + 1;
        
        try {
          final athlete = _parseAthleteFromRow(row, headers, rowNumber);
          if (athlete != null) {
            athletes.add(athlete);
          }
        } catch (e) {
          errors.add('Row $rowNumber: ${e.toString()}');
        }
      }

      return CsvParseResult(
        athletes: athletes,
        errors: errors,
        warnings: warnings,
        totalRows: csvData.length - 1,
        validRows: athletes.length,
      );

    } catch (e) {
      return CsvParseResult(
        athletes: [],
        errors: ['Failed to parse CSV file: ${e.toString()}'],
        warnings: [],
        totalRows: 0,
        validRows: 0,
      );
    }
  }

  /// Validate CSV headers
  List<String> _validateHeaders(List<String> headers) {
    final errors = <String>[];
    
    // Check for required headers only
    final missingHeaders = <String>[];
    for (final requiredHeader in _requiredHeaders) {
      if (!headers.contains(requiredHeader)) {
        missingHeaders.add(requiredHeader);
      }
    }
    
    if (missingHeaders.isNotEmpty) {
      errors.add('Missing required columns: ${missingHeaders.join(', ')}');
    }
    
    // Check for duplicate headers
    final duplicates = <String>[];
    final seen = <String>{};
    for (final header in headers) {
      if (seen.contains(header)) {
        duplicates.add(header);
      }
      seen.add(header);
    }
    
    if (duplicates.isNotEmpty) {
      errors.add('Duplicate columns found: ${duplicates.join(', ')}');
    }
    
    // Check for unknown headers (warn but don't error)
    final unknownHeaders = <String>[];
    for (final header in headers) {
      if (!_allHeaders.contains(header)) {
        unknownHeaders.add(header);
      }
    }
    
    if (unknownHeaders.isNotEmpty) {
      // This is just a warning, not an error
      // Could add to warnings in parseResult if needed
    }
    
    return errors;
  }

  /// Parse a single CSV row into an Athlete object
  Athlete? _parseAthleteFromRow(List<dynamic> row, List<String> headers, int rowNumber) {
    // Create a map from headers to values
    final rowData = <String, String>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      rowData[headers[i]] = row[i]?.toString().trim() ?? '';
    }
    
    // Validate required fields
    final name = rowData['name'] ?? '';
    final sport = rowData['sport'] ?? '';
    
    if (name.isEmpty) {
      throw Exception('Name is required');
    }
    
    if (sport.isEmpty) {
      throw Exception('Sport is required');
    }
    
    // Parse optional fields
    final isParaAthleteStr = (rowData['is_para_athlete'] ?? '').toLowerCase();
    final isParaAthlete = isParaAthleteStr == 'true' || 
                         isParaAthleteStr == 'yes' || 
                         isParaAthleteStr == '1';
    
    DateTime? dob;
    final dobStr = rowData['dob'] ?? '';
    if (dobStr.isNotEmpty) {
      try {
        dob = DateTime.parse(dobStr);
      } catch (e) {
        throw Exception('Invalid date format for DOB. Use YYYY-MM-DD format.');
      }
    }
    
    final placeOfBirth = rowData['place_of_birth'] ?? '';
    final education = rowData['education'] ?? '';
    final imageUrl = rowData['image_url'];
    
    return Athlete.fromCsv(
      name: name,
      sport: sport,
      isParaAthlete: isParaAthlete,
      dob: dob,
      placeOfBirth: placeOfBirth,
      education: education,
      imageUrl: imageUrl,
    );
  }

  /// Generate sample CSV content with required fields only
  String generateSampleCsv() {
    final sampleData = [
      _requiredHeaders,
      [
        'Virat Kohli',
        'Cricket',
        'false',
        '1988-11-05',
        'Delhi, India',
      ],
      [
        'P.V. Sindhu',
        'Badminton',
        'false',
        '1995-07-05',
        'Hyderabad, India',
      ],
      [
        'Devendra Jhajharia',
        'Athletics',
        'true',
        '1981-06-10',
        'Churu, Rajasthan',
      ],
    ];
    
    return const ListToCsvConverter().convert(sampleData);
  }

  /// Generate comprehensive sample CSV content with all fields
  String generateComprehensiveSampleCsv() {
    final sampleData = [
      _allHeaders,
      [
        'Virat Kohli',
        'Cricket',
        'false',
        '1988-11-05',
        'Delhi, India',
        'Vishal Bharti Public School',
        'https://storage.googleapis.com/sporteve/athletes/virat_kohli.jpg',
      ],
      [
        'P.V. Sindhu',
        'Badminton',
        'false',
        '1995-07-05',
        'Hyderabad, India',
        'St. Ann\'s College',
        'https://storage.googleapis.com/sporteve/athletes/pv_sindhu.jpg',
      ],
      [
        'Devendra Jhajharia',
        'Athletics',
        'true',
        '1981-06-10',
        'Churu, Rajasthan',
        'Government School',
        '',
      ],
    ];
    
    return const ListToCsvConverter().convert(sampleData);
  }

  /// Get CSV template with required headers only
  String getCsvTemplate() {
    return const ListToCsvConverter().convert([_requiredHeaders]);
  }

  /// Get comprehensive CSV template with all supported headers
  String getComprehensiveCsvTemplate() {
    return const ListToCsvConverter().convert([_allHeaders]);
  }

  /// Validate individual athlete data
  List<String> validateAthleteData(Athlete athlete) {
    final errors = <String>[];
    
    if (athlete.name.trim().isEmpty) {
      errors.add('Name is required');
    }
    
    if (athlete.sport.trim().isEmpty) {
      errors.add('Sport is required');
    }
    
    if (athlete.dob != null) {
      final now = DateTime.now();
      if (athlete.dob!.isAfter(now)) {
        errors.add('Date of birth cannot be in the future');
      }
      
      final age = now.year - athlete.dob!.year;
      if (age > 150) {
        errors.add('Age seems unrealistic (over 150 years)');
      }
      if (age < 5) {
        errors.add('Age seems too young for professional sports (under 5 years)');
      }
    }
    
    if (athlete.imageUrl != null && athlete.imageUrl!.isNotEmpty) {
      final uri = Uri.tryParse(athlete.imageUrl!);
      if (uri == null || !uri.hasScheme) {
        errors.add('Invalid image URL format');
      }
    }
    
    return errors;
  }

  /// Get list of supported sports for validation
  static const List<String> supportedSports = [
    'Football',
    'Basketball',
    'Tennis',
    'Cricket',
    'Baseball',
    'Soccer',
    'Golf',
    'Swimming',
    'Athletics',
    'Boxing',
    'Wrestling',
    'Volleyball',
    'Badminton',
    'Table Tennis',
    'Hockey',
    'Rugby',
    'Cycling',
    'Gymnastics',
    'Weightlifting',
    'Archery',
    'Shooting',
    'Rowing',
    'Sailing',
    'Equestrian',
    'Fencing',
    'Judo',
    'Karate',
    'Taekwondo',
    'Skiing',
    'Snowboarding',
    'Figure Skating',
    'Speed Skating',
    'Ice Hockey',
    'Curling',
    'Bobsled',
    'Luge',
    'Skeleton',
    'Biathlon',
    'Cross Country Skiing',
    'Ski Jumping',
    'Nordic Combined',
  ];
}
