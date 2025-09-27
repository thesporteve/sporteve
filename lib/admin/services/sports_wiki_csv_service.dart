import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import '../../models/sport_wiki.dart';

class SportsWikiCsvService {
  static final SportsWikiCsvService _instance = SportsWikiCsvService._internal();
  factory SportsWikiCsvService() => _instance;
  SportsWikiCsvService._internal();

  /// CSV headers for sports wiki bulk import (basic fields only)
  static const List<String> _requiredHeaders = [
    'name',           // Sport name (required)
    'category',       // Team/Individual/Mixed (required) 
    'type',           // Outdoor/Indoor/Water/Combat (required)
  ];

  static const List<String> _optionalHeaders = [
    'description',    // Basic description (optional)
    'display_name',   // UI display name (optional)
    'icon_name',      // Material icon name (optional)
    'primary_color',  // Hex color (optional)
    'is_active',      // Active status (optional, defaults to true)
    'sort_order',     // Display order (optional, defaults to 1000)
  ];

  /// Parse CSV data and return list of SportWiki objects
  static Future<List<SportWiki>> parseCsvData(
    String csvContent, {
    bool hasHeaders = true,
  }) async {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      List<String> headers;
      List<List<dynamic>> dataRows;

      if (hasHeaders) {
        headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
        dataRows = rows.skip(1).toList();
      } else {
        headers = _requiredHeaders;
        dataRows = rows;
      }

      // Validate required headers
      final missingHeaders = _requiredHeaders.where((h) => !headers.contains(h)).toList();
      if (missingHeaders.isNotEmpty) {
        throw Exception('Missing required headers: ${missingHeaders.join(', ')}');
      }

      final List<SportWiki> sports = [];
      
      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        try {
          final sportWiki = _parseRowToSportWiki(headers, row, i + 2); // +2 for 1-based index + header
          sports.add(sportWiki);
        } catch (e) {
          throw Exception('Error in row ${i + 2}: $e');
        }
      }

      return sports;
    } catch (e) {
      throw Exception('Failed to parse CSV: $e');
    }
  }

  /// Convert row data to SportWiki object
  static SportWiki _parseRowToSportWiki(List<String> headers, List<dynamic> row, int rowNumber) {
    final Map<String, String> data = {};
    
    for (int i = 0; i < headers.length && i < row.length; i++) {
      data[headers[i]] = row[i].toString().trim();
    }

    // Validate required fields
    final name = data['name'];
    if (name == null || name.isEmpty) {
      throw Exception('Name is required');
    }

    final category = data['category'];
    if (category == null || category.isEmpty) {
      throw Exception('Category is required');
    }

    final type = data['type'];
    if (type == null || type.isEmpty) {
      throw Exception('Type is required');
    }

    // Validate category
    const validCategories = ['Team Sport', 'Individual Sport', 'Mixed Sport'];
    if (!validCategories.any((cat) => cat.toLowerCase() == category.toLowerCase())) {
      throw Exception('Category must be one of: ${validCategories.join(', ')}');
    }

    // Validate type
    const validTypes = ['Outdoor', 'Indoor', 'Water', 'Combat'];
    if (!validTypes.any((t) => t.toLowerCase() == type.toLowerCase())) {
      throw Exception('Type must be one of: ${validTypes.join(', ')}');
    }

    // Parse optional boolean and int fields
    bool isActive = true;
    if (data['is_active'] != null && data['is_active']!.isNotEmpty) {
      final activeValue = data['is_active']!.toLowerCase();
      isActive = activeValue == 'true' || activeValue == '1' || activeValue == 'yes';
    }

    int sortOrder = 1000;
    if (data['sort_order'] != null && data['sort_order']!.isNotEmpty) {
      sortOrder = int.tryParse(data['sort_order']!) ?? 1000;
    }

    return SportWiki(
      id: '', // Will be set by Firestore
      name: name,
      category: _capitalizeWords(category),
      type: _capitalizeWords(type),
      description: data['description'] ?? '',
      // UI-specific fields
      displayName: data['display_name']?.isEmpty ?? true ? null : data['display_name'],
      iconName: data['icon_name']?.isEmpty ?? true ? null : data['icon_name'],
      primaryColor: data['primary_color']?.isEmpty ?? true ? null : data['primary_color'],
      isActive: isActive,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  /// Capitalize first letter of each word
  static String _capitalizeWords(String text) {
    return text.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
    ).join(' ');
  }

  /// Validate CSV format and return errors
  static List<String> validateCsvFormat(String csvContent) {
    final List<String> errors = [];

    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);
      
      if (rows.isEmpty) {
        errors.add('CSV file is empty');
        return errors;
      }

      final headers = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Check required headers
      for (final requiredHeader in _requiredHeaders) {
        if (!headers.contains(requiredHeader)) {
          errors.add('Missing required header: $requiredHeader');
        }
      }

      // Validate data rows
      final dataRows = rows.skip(1).toList();
      if (dataRows.isEmpty) {
        errors.add('No data rows found');
        return errors;
      }

      for (int i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        final rowNumber = i + 2; // +2 for 1-based index + header

        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        // Check required fields
        final nameIndex = headers.indexOf('name');
        final categoryIndex = headers.indexOf('category');
        final typeIndex = headers.indexOf('type');

        if (nameIndex >= 0 && (nameIndex >= row.length || row[nameIndex].toString().trim().isEmpty)) {
          errors.add('Row $rowNumber: Name is required');
        }

        if (categoryIndex >= 0 && (categoryIndex >= row.length || row[categoryIndex].toString().trim().isEmpty)) {
          errors.add('Row $rowNumber: Category is required');
        }

        if (typeIndex >= 0 && (typeIndex >= row.length || row[typeIndex].toString().trim().isEmpty)) {
          errors.add('Row $rowNumber: Type is required');
        }

        // Validate category values
        if (categoryIndex >= 0 && categoryIndex < row.length) {
          final category = row[categoryIndex].toString().trim();
          if (category.isNotEmpty) {
            const validCategories = ['team sport', 'individual sport', 'mixed sport'];
            if (!validCategories.contains(category.toLowerCase())) {
              errors.add('Row $rowNumber: Invalid category "$category". Must be: Team Sport, Individual Sport, or Mixed Sport');
            }
          }
        }

        // Validate type values
        if (typeIndex >= 0 && typeIndex < row.length) {
          final type = row[typeIndex].toString().trim();
          if (type.isNotEmpty) {
            const validTypes = ['outdoor', 'indoor', 'water', 'combat'];
            if (!validTypes.contains(type.toLowerCase())) {
              errors.add('Row $rowNumber: Invalid type "$type". Must be: Outdoor, Indoor, Water, or Combat');
            }
          }
        }

        // Validate boolean fields
        final isActiveIndex = headers.indexOf('is_active');
        if (isActiveIndex >= 0 && isActiveIndex < row.length) {
          final isActiveValue = row[isActiveIndex].toString().trim().toLowerCase();
          if (isActiveValue.isNotEmpty && !['true', 'false', '1', '0', 'yes', 'no'].contains(isActiveValue)) {
            errors.add('Row $rowNumber: Invalid is_active value "$isActiveValue". Must be: true/false, 1/0, or yes/no');
          }
        }

        // Validate sort_order
        final sortOrderIndex = headers.indexOf('sort_order');
        if (sortOrderIndex >= 0 && sortOrderIndex < row.length) {
          final sortOrderValue = row[sortOrderIndex].toString().trim();
          if (sortOrderValue.isNotEmpty && int.tryParse(sortOrderValue) == null) {
            errors.add('Row $rowNumber: Invalid sort_order "$sortOrderValue". Must be a number');
          }
        }
      }
    } catch (e) {
      errors.add('Failed to parse CSV: ${e.toString()}');
    }
    
    return errors;
  }

  /// Generate sample CSV content for download
  static String generateSampleCsv() {
    const headers = _requiredHeaders;
    const sampleData = [
      ['Cricket', 'Team Sport', 'Outdoor'],
      ['Chess', 'Individual Sport', 'Indoor'],
      ['Swimming', 'Individual Sport', 'Water'],
    ];
    
    final List<List<String>> csvData = [headers, ...sampleData];
    return const ListToCsvConverter().convert(csvData);
  }

  /// Generate comprehensive sample CSV with all fields
  static String generateComprehensiveSampleCsv() {
    final allHeaders = [..._requiredHeaders, ..._optionalHeaders];
    const sampleData = [
      ['Cricket', 'Team Sport', 'Outdoor', 'A bat-and-ball game', 'Cricket', 'sports_cricket', '#4CAF50', 'true', '100'],
      ['Chess', 'Individual Sport', 'Indoor', 'Strategic board game', 'Chess', 'sports_esports', '#9C27B0', 'true', '200'],
      ['Swimming', 'Individual Sport', 'Water', 'Aquatic sport', 'Swimming', 'pool', '#2196F3', 'true', '300'],
    ];
    
    final List<List<String>> csvData = [allHeaders, ...sampleData];
    return const ListToCsvConverter().convert(csvData);
  }

  /// Get CSV template with headers only
  static String getCsvTemplate() {
    return const ListToCsvConverter().convert([_requiredHeaders]);
  }

  /// Get comprehensive CSV template with all headers
  static String getComprehensiveCsvTemplate() {
    final allHeaders = [..._requiredHeaders, ..._optionalHeaders];
    return const ListToCsvConverter().convert([allHeaders]);
  }

  /// Convert string to bytes for download
  static Uint8List stringToBytes(String content) {
    return Uint8List.fromList(utf8.encode(content));
  }

  /// Get supported categories for validation
  static const List<String> supportedCategories = [
    'Team Sport',
    'Individual Sport', 
    'Mixed Sport',
  ];

  /// Get supported types for validation
  static const List<String> supportedTypes = [
    'Outdoor',
    'Indoor',
    'Water',
    'Combat',
  ];
}
