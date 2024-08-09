import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class Score {
  int score;

  Score(this.score);

  Map<String, dynamic> toJson(){
    return {'score': score};
  }
  static Score fromJson(Map<String, dynamic> json){
    return Score(json['score']);
  }
}

class Subject {
  String name;
  List<Score> scores;

  Subject(this.name, this.scores);

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'scores': scores.map((s) => s.toJson()).toList(),
    };
  }

  static Subject fromJson(Map<String, dynamic> json) {
    return Subject(json['name'], (json['scores'] as List).map((s) => Score.fromJson(s)).toList());
  }
}

class Student {
  int id;
  String name;
  List<Subject> subjects;

  Student(this.id, this.name, this.subjects);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjects': subjects.map((s) => s.toJson()).toList(),
    };
  }

  static Student fromJson(Map<String, dynamic> json) {
    return Student(json['id'], json['name'], (json['subjects'] as List).map((s) => Subject.fromJson(s)).toList());
  }

  @override
  String toString() {
    return 'ID: $id, Name: $name, Subjects: ${subjects.map((s) => s.name).join(', ')}';
  }
}
void main() async{
  const String fileName = 'students.json';
  final String directoryPath = p.join(Directory.current.path, 'data');
  final Directory directory = Directory(directoryPath);

  if(!await directory.exists()){
    await directory.create(recursive: true);
  }
  final String filePath = p.join(directoryPath, fileName);
  List<Student> studentList = await loadStudents(filePath);

  while(true){
    print('''
    1. Hiển thị toàn bộ sinh viên.
    2. Thêm sinh viên.
    3. Xóa sinh viên
    4. Sửa thông tin sinh viên.
    5. Tìm kiếm sinh viên theo Tên hoặc ID.
    6. Hiển thị sinh viên có điểm thi môn cao nhất.
    7. Thoát
       Mời bạn chọn:
    ''');
    String? choice = stdin.readLineSync();
    switch(choice){
      case '1':
        displayStudents(studentList);
        break;
      case '2':
        await addStudent(filePath, studentList);
        break;
      case '3':
        await deleteStudent(filePath, studentList);
        break;
      case '4':
        await editStudent(filePath, studentList);
        break;
      case '5':
        searchStudent(studentList);
        break;
      case '6':
        findTopStudentsBySubject(studentList);
        break;
      case '7':
        print('Thoát chương trình!');
        exit(0);
      default:
        print('Vui lòng chọn lại!');
    }
  }
}
Future<List<Student>> loadStudents(String filePath) async {
  if (!File(filePath).existsSync()) {
    await File(filePath).create();
    await File(filePath).writeAsString(jsonEncode([]));
    return [];
  }
  String content = await File(filePath).readAsString();
  List<dynamic> jsonData = jsonDecode(content);
  return jsonData.map((json) => Student.fromJson(json)).toList();
}

Future<void> saveStudents(String filePath, List<Student> studentList) async {
  String jsonContent = jsonEncode(studentList.map((s) => s.toJson()).toList());
  await File(filePath).writeAsString(jsonContent);
}
void displayStudents(List<Student> studentList){
  if(studentList.isEmpty){
    print('Danh sách sinh viên trống!');
  }else{
    print('Danh sách sinh viên: ');
    for(var student in studentList){
      print(student);
      for(var subject in student.subjects){
        print('  Môn: ${subject.name}, Điểm: ${subject.scores.map((s) => s.score).join(', ')}');
      }
    }
  }
}
void searchStudent(List<Student> studentList){
  print('Nhập tên hoặc ID sinh viên cần tìm: ');
  String? query = stdin.readLineSync();
  if(query == null || query.isEmpty){
    print('Không hợp lệ!');
    return;
  }
  int? idQuery = int.tryParse(query);
  Student? student = studentList.firstWhere(
          (s) => s.id == idQuery || s.name.toLowerCase() == query.toLowerCase(),
      orElse: () => Student(0, '', []));
  if(student.id == 0){
    print('Không tìm thấy sinh viên với thông tin này!');
    return;
  }
  print('Kết quả tìm kiếm: ');
  print(student);
  for(var subject in student.subjects){
    print('  Môn: ${subject.name}, Điểm: ${subject.scores.map((s) => s.score).join(', ')}');
  }
}
void findTopStudentsBySubject(List<Student> studentList){
  print('Nhập tên môn học: ');
  String? subjectName = stdin.readLineSync();
  if(subjectName == null || subjectName.isEmpty){
    print('Tên môn học không hợp lệ!');
    return;
  }
  int highestScore = -1;
  List<Student> topStudents = [];

  for (var student in studentList) {
    for (var subject in student.subjects) {
      if (subject.name.toLowerCase() == subjectName.toLowerCase()) {
        int maxScore = subject.scores.map((s) => s.score).reduce((a, b) => a > b ? a : b);
        if (maxScore > highestScore) {
          highestScore = maxScore;
          topStudents = [student];
        } else if (maxScore == highestScore) {
          topStudents.add(student);
        }
      }
    }
  }

  if (topStudents.isEmpty) {
    print('Không tìm thấy môn học: $subjectName.');
  } else {
    print('Sinh viên có điểm cao nhất trong môn $subjectName:');
    for (var student in topStudents) {
      print(student);
    }
  }
}
Future<void> addStudent(String filePath, List<Student> studentList) async {
  print('Nhập tên sinh viên: ');
  String? name = stdin.readLineSync();
  if (name == null || name.isEmpty) {
    print('Tên không hợp lệ!');
    return;
  }
  List<Subject> subjects = [];
  while (true) {
    print('Nhập tên môn học (để trống để dừng): ');
    String? subjectName = stdin.readLineSync();
    if (subjectName == null || subjectName.isEmpty) break;

    print('Nhập điểm cho môn học $subjectName (nhập cách nhau bởi dấu phẩy): ');
    String? scoreInput = stdin.readLineSync();
    if (scoreInput == null || scoreInput.isEmpty) continue;

    List<Score> scores = scoreInput.split(',').map((s) => Score(int.parse(s.trim()))).toList();
    subjects.add(Subject(subjectName, scores));
  }

  int id = studentList.isEmpty ? 1 : studentList.last.id + 1;
  Student student = Student(id, name, subjects);
  studentList.add(student);
  await saveStudents(filePath, studentList);
  print('Thêm sinh viên thành công!');
}
Future<void> editStudent(String filePath, List<Student> studentList) async {
  print('Nhập ID sinh viên cần sửa: ');
  String? idStr = stdin.readLineSync();
  if (idStr == null || idStr.isEmpty) {
    print('ID không hợp lệ!');
    return;
  }
  int id = int.parse(idStr);
  Student? student = studentList.firstWhere((s) => s.id == id, orElse: () => Student(0, '', []));

  if (student.id == 0) {
    print('Không tìm thấy sinh viên với ID này!');
    return;
  }

  print('Nhập tên mới (để trống để giữ nguyên): ');
  String? newName = stdin.readLineSync();
  if (newName != null && newName.isNotEmpty) {
    student.name = newName;
  }

  print('Chỉnh sửa môn học (1 - Thêm môn, 2 - Sửa môn, 3 - Xóa môn, 4 - Không làm gì): ');
  String? action = stdin.readLineSync();
  switch (action) {
    case '1':
      await addSubjects(student);
      break;
    case '2':
      await editSubjects(student);
      break;
    case '3':
      await deleteSubject(student);
      break;
    case '4':
      break;
    default:
      print('Lựa chọn không hợp lệ!');
  }

  await saveStudents(filePath, studentList);
  print('Chỉnh sửa sinh viên thành công!');
}

Future<void> addSubjects(Student student) async {
  while (true) {
    print('Nhập tên môn học (để trống để dừng): ');
    String? subjectName = stdin.readLineSync();
    if (subjectName == null || subjectName.isEmpty) break;

    print('Nhập điểm cho môn học $subjectName (nhập cách nhau bởi dấu phẩy): ');
    String? scoreInput = stdin.readLineSync();
    if (scoreInput == null || scoreInput.isEmpty) continue;

    List<Score> scores = scoreInput.split(',').map((s) => Score(int.parse(s.trim()))).toList();
    student.subjects.add(Subject(subjectName, scores));
  }
}
Future<void> editSubjects(Student student) async {
  print('Nhập tên môn học cần sửa: ');
  String? subjectName = stdin.readLineSync();
  if (subjectName == null || subjectName.isEmpty) {
    print('Tên môn không hợp lệ!');
    return;
  }
  Subject? subject = student.subjects.firstWhere((s) => s.name.toLowerCase() == subjectName.toLowerCase(), orElse: () => Subject('', []));

  if (subject.name.isEmpty) {
    print('Không tìm thấy môn học này!');
    return;
  }

  print('Nhập điểm mới cho môn học $subjectName (nhập cách nhau bởi dấu phẩy): ');
  String? scoreInput = stdin.readLineSync();
  if (scoreInput != null && scoreInput.isNotEmpty) {
    subject.scores = scoreInput.split(',').map((s) => Score(int.parse(s.trim()))).toList();
  }
}

Future<void> deleteSubject(Student student) async {
  print('Nhập tên môn học cần xóa: ');
  String? subjectName = stdin.readLineSync();
  if (subjectName == null || subjectName.isEmpty) {
    print('Tên môn không hợp lệ!');
    return;
  }
  student.subjects.removeWhere((s) => s.name.toLowerCase() == subjectName.toLowerCase());
}
Future<void> deleteStudent(String filePath, List<Student> studentList) async {
  print('Nhập ID sinh viên cần xóa: ');
  String? idStr = stdin.readLineSync();
  if (idStr == null || idStr.isEmpty) {
    print('ID không hợp lệ!');
    return;
  }
  int id = int.parse(idStr);
  studentList.removeWhere((s) => s.id == id);
  await saveStudents(filePath, studentList);
  print('Xóa sinh viên thành công!');
}
