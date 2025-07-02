import '../models/group.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final List<Group> _groups = [];
  int _nextId = 1;

  Future<String> addGroup(Group group) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newGroup = Group(
      id: _nextId.toString(),
      name: group.name,
      location: group.location,
      numberOfPeople: group.numberOfPeople,
      createdAt: group.createdAt,
      createdBy: group.createdBy,
      members: group.members,
    );
    
    _groups.add(newGroup);
    _nextId++;
    
    return newGroup.id;
  }

  Future<List<Group>> getAllGroups() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_groups);
  }

  Future<Group?> getGroupById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _groups.firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }
}