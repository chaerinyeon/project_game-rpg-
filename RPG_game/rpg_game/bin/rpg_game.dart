// ignore_for_file: unused_local_variable, prefer_typing_uninitialized_variables, await_only_futures

import 'dart:io';
import 'dart:math';

class Character {
  String name;
  int health;
  int attack;
  int defense;

  Character(this.name, this.health, this.attack, this.defense);

  void attackMonster(Monster monster) {
    int damage = max(0, attack - monster.defense);
    monster.health -= damage;
    print('$name 이/가 ${monster.name}에게 $damage 의 데미지를 입혔습니다.');
  }

  void defend() {
    int regainedHealth = (health * 0.1).round(); // Regain 10% of current health
    health += regainedHealth;
    print('$name 이/가 방어태세를 취하여 $regainedHealth 만큼 체력을 얻었습니다.');
  }

  void showStatus() {
    print('$name - 체력: $health, 공격력: $attack, 방어력: $defense');
  }
}

class Monster {
  String name;
  int health;
  late int attack;
  int defense;

  Monster(this.name, this.health, int maxAttackPower, this.defense) {
    attack = Random().nextInt(maxAttackPower) + 1;
  }

  void attackCharacter(Character character) {
    int damage = max(0, attack - character.defense);
    character.health -= damage;
    print('몬스터 $name 이/가 ${character.name} 에게 $damage 의 데미지를 입혔습니다.');
  }

  void showStatus() {
    print('$name - 체력: $health, 공격력: $attack');
  }
}

String getCharacterName() {
  stdout.write('캐릭터 이름을 입력하세요. (한글, 영어 대소문자만 가능): ');
  String? name = stdin.readLineSync();
  while (name == null || !RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
    print("유효하지 않은 이름입니다. 특수 문자나 숫자를 제외한 올바른 이름을 입력해주세요.");
    stdout.write("캐릭터 이름을 입력해주세요: ");
    name = stdin.readLineSync();
  }
  return name;
}

class Game {
  Character? character;
  List<Monster> monsterList =
      []; // Properly initialize as an empty list to avoid null issues
  int monsterDefeated = 0;

  Future<void> startGame() async {
    try {
      character = await loadCharacterStatus(); // Assign the character instance
      if (character == null) {
        print("게임을 시작할 수 없습니다. 캐릭터 데이터를 불러오지 못했습니다.");
        return; // Exit the startGame method if character is null
      }

      monsterList = await loadMonsterStatus(); // Assign the monster list
      if (monsterList.isEmpty) {
        print("게임을 시작할 수 없습니다. 몬스터 데이터가 없습니다.");
        return; // Exit the startGame method if monster list is empty
      }

      print('게임을 시작합니다!');

      while (character!.health > 0 && monsterList.isNotEmpty) {
        Monster monster = getRandomMonster();
        print(
            "현재 캐릭터 체력: ${character!.health}, 남은 몬스터 수: ${monsterList.length}");

        battle(monster);

        if (character!.health <= 0) {
          print('Game Over! 패배하였습니다');
          saveResult('패배');
          break;
        }

        if (monsterList.isNotEmpty) {
          stdout.write('다음 몬스터와 대결하시겠습니까? (y/n): ');
          String? input = stdin.readLineSync();
          if (input == null || input.toLowerCase() != 'y') {
            print('게임을 종료하겠습니다.');
            saveResult('중도 종료');
            return; // Explicitly exit the game if the player chooses to quit
          } else {
            print('새로운 몬스터와 대결합니다!');
          }
        }
      }

      if (monsterList.isEmpty) {
        print('축하합니다! 모든 몬스터를 물리쳤습니다.');
        saveResult('승리');
      }
    } catch (e) {
      print('게임을 시작할 수 없습니다: $e');
    }
  }

  Future<Character?> loadCharacterStatus() async {
    try {
      final file = File('characterstatus.txt');
      if (!file.existsSync()) {
        throw FileSystemException("characterstatus.txt 파일이 존재하지 않습니다.");
      }
      final contents = await file.readAsString();
      final stats = contents.split(',');
      if (stats.length != 3) {
        throw FormatException(
            'Invalid characterstatus.txt format. Expected 3 values.');
      }

      int health = int.parse(stats[0].trim());
      int attack = int.parse(stats[1].trim());
      int defense = int.parse(stats[2].trim());

      String name = getCharacterName();
      Character character = Character(name, health, attack, defense);
      print('캐릭터 상태가 성공적으로 불러와졌습니다.');
      return character; // Properly returning the character instance
    } catch (e) {
      print('캐릭터 데이터를 불러오는 데 실패했습니다: $e');
      return null; // Return null if loading fails
    }
  }

  Future<List<Monster>> loadMonsterStatus() async {
    try {
      final file = File('monsterstatus.txt');
      if (!file.existsSync()) {
        throw FileSystemException("monsterstatus.txt 파일이 존재하지 않습니다.");
      }
      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        throw FormatException('monsterstatus.txt 파일이 비어 있습니다.');
      }

      List<Monster> monsters = [];

      for (var line in lines) {
        if (line.trim().isEmpty) continue;

        final stats = line.split(',');
        if (stats.length != 3) {
          throw FormatException('Invalid format in monsterstatus.txt: $line');
        }

        String name = stats[0].trim();
        int health = int.parse(stats[1].trim());
        int maxAttackPower = int.parse(stats[2].trim());

        Monster monster = Monster(name, health, maxAttackPower, 0);
        monsters.add(monster);
      }

      print("몬스터 상태가 성공적으로 불러와졌습니다.");
      return monsters;
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      return []; // Return an empty list if loading fails
    }
  }

  void battle(Monster monster) {
    if (monsterList.isEmpty) {
      print("더 이상 남은 몬스터가 없습니다.");
      return;
    }

    print('새로운 몬스터 ${monster.name} 이/가 나타났습니다!');
    character!.showStatus();
    monster.showStatus();

    while (character!.health > 0 && monster.health > 0) {
      stdout.write('행동을 선택하세요 (1: 공격 , 2: 방어): ');
      String? action = stdin.readLineSync();
      if (action == '1') {
        character!.attackMonster(monster);
      } else if (action == '2') {
        character!.defend();
      } else {
        print('잘못된 입력입니다. 1 또는 2를 선택해주세요.');
        continue;
      }

      character!.showStatus();
      monster.showStatus();

      if (monster.health <= 0) {
        print('몬스터 ${monster.name} 을/를 물리쳤습니다.');
        monsterDefeated++;
        monsterList.remove(monster);
        break;
      }

      print('${monster.name}의 차례');
      monster.attackCharacter(character!);

      character!.showStatus();
      monster.showStatus();
    }
  }

  Monster getRandomMonster() {
    return monsterList[Random().nextInt(monsterList.length)];
  }

  void saveResult(String result) {
    stdout.write('결과를 저장하시겠습니까? (y/n): ');
    String? save = stdin.readLineSync();
    if (save != null && save.toLowerCase() == 'y') {
      File file = File('result.txt');
      file.writeAsStringSync(
          '캐릭터 이름: ${character!.name}, 남아있는 체력: ${character!.health}, 게임 결과: $result');
      print('결과를 result.txt에 저장하였습니다.');
    }
  }
}

void main() async {
  Game game = Game();
  await game.startGame();
}
