class Purchase {
  final String id;
  final String groupId;
  final String name;
  final List<String> payees;
  final Map<String, double> amounts; 
  final String splitMethod;
  final String? receiptUrl;

  Purchase({
    required this.id,
    required this.groupId,
    required this.name,
    required this.payees,
    required this.amounts,
    required this.splitMethod,
    this.receiptUrl,
  });
}