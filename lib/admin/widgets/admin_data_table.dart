import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class AdminDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool sortAscending;
  final int? sortColumnIndex;

  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortAscending = true,
    this.sortColumnIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              sortAscending: sortAscending,
              sortColumnIndex: sortColumnIndex,
              headingRowHeight: 56,
              dataRowHeight: 72,
              columnSpacing: 24,
              horizontalMargin: 16,
              showCheckboxColumn: false,
              decoration: const BoxDecoration(),
              headingTextStyle: AdminTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AdminTheme.primaryColor,
              ),
              dataTextStyle: AdminTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
