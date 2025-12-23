import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class LoginSQLiteHelper {
  static Database? _database;

  // Initialize database
  static Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    print('🔄 Initializing SQLite database...');
    _database = await _initDatabase();
    print('✅ Database initialization completed');
    return _database!;
  }

  // Helper method to create login_data table
  static Future<void> _createLoginTable(Database db) async {
    try {
      // await db.execute('DROP TABLE IF EXISTS login_data');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS login_data (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          manager_name TEXT,
          profile_image TEXT,
          registered_movie TEXT,
          mobile_number TEXT,
          subUnitName TEXT,
          password TEXT,
          project_id TEXT,
          production_type_id INTEGER,
          production_house TEXT,
          vmid INTEGER,
          login_date TEXT,
          vsid TEXT,
          vpid TEXT,
          vuid INTEGER,
          companyName TEXT,
          email TEXT,
          vbpid INTEGER,
          vcid INTEGER,
          vsubid INTEGER,
          vpoid INTEGER,
          mtypeId INTEGER,
          unitName TEXT,
          vmTypeId INTEGER,
          idcardurl TEXT,
          vpidpo INTEGER,
          vpidbp INTEGER,
          unitid INTEGER,
          subunitid INTEGER,
          platformlogo TEXT,
          isAgentt INTEGER DEFAULT 0,
          driver BOOLEAN DEFAULT 0
        )
      ''');
      // Migration: if table already existed without 'isAgentt' column, add it.
      try {
        final columns = await db.rawQuery('PRAGMA table_info(login_data)');
        final columnNames = columns.map((c) => c['name']?.toString()).toList();
        if (!columnNames.contains('isAgentt')) {
          print('🔧 Adding missing column isAgentt to login_data table');
          await db.execute(
              'ALTER TABLE login_data ADD COLUMN isAgentt INTEGER DEFAULT 0');
          print('✅ Column isAgentt added');
        }
      } catch (e) {
        print('⚠️ Migration check for isAgentt failed: $e');
      }
      print('✅ SQLite login_data table created/verified successfully');
    } catch (e) {
      print('❌ Error creating login_data table: $e');
      rethrow;
    }
  }

  // Create database and login table (with profile_image field)
  static Future<Database> _initDatabase() async {
    try {
      String dbPath = path.join(await getDatabasesPath(), 'dubbing_login.db');
      print('📍 Database path: $dbPath');

      final db = await openDatabase(
        dbPath,
        version: 4, // Increment version to force recreation
        onCreate: (Database db, int version) async {
          print('🔨 onCreate: Creating login_data table...');
          await _createLoginTable(db);
        },
        onOpen: (Database db) async {
          print('📂 onOpen: Ensuring login_data table exists...');
          await _createLoginTable(db);
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          print('⬆️ onUpgrade: Recreating login_data table...');
          await db.execute('DROP TABLE IF EXISTS login_data');
          await _createLoginTable(db);
        },
      );

      // Test database connectivity
      final tables = await db
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      print('📋 Available tables: $tables');

      return db;
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  // Save login data to SQLite (ONLY if table is empty - first user only)
  static Future<void> saveLoginData({
    required Map<String, dynamic>? loginresponsebody,
    required dynamic loginresult,
    required String mobileNumber,
    required String password,
    String? profileImage,
  }) async {
    try {
      print('🔄 Starting saveLoginData...');
      final db = await database;
      print('✅ Database connection obtained');

      // Ensure table exists before any operations
      await _createLoginTable(db);
      print('✅ Login table verified/created');

      // Helpers
      String safeString(dynamic v) => (v == null) ? '' : v.toString();
      int safeInt(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is double) return v.toInt();
        final s = v.toString();
        return int.tryParse(s) ?? 0;
      }

      // Flexible extractor: check loginresult (Map/List), responseData (Map/List) and root
      dynamic _getFromResponse(String key) {
        // 1) loginresult (preferred)
        if (loginresult != null) {
          if (loginresult is Map && (loginresult as Map).containsKey(key)) {
            return (loginresult as Map)[key];
          }
          if (loginresult is List && (loginresult as List).isNotEmpty) {
            final first = (loginresult as List)[0];
            if (first is Map && first.containsKey(key)) return first[key];
          }
        }

        // 2) loginresponsebody['responseData']
        final rd = loginresponsebody?['responseData'];
        if (rd != null) {
          if (rd is Map && rd.containsKey(key)) return rd[key];
          if (rd is List && rd.isNotEmpty) {
            final first = rd[0];
            if (first is Map && first.containsKey(key)) return first[key];
          }
        }

        // 3) root-level in loginresponsebody
        if (loginresponsebody is Map &&
            (loginresponsebody as Map).containsKey(key)) {
          return (loginresponsebody as Map)[key];
        }

        return null;
      }

      // Extract commonly-used fields robustly
      final extractedSubUnitName = safeString(
          _getFromResponse('subUnitName') ?? _getFromResponse('subunitName'));
      final extractedProfileImage = safeString(
          _getFromResponse('profileImage') ??
              _getFromResponse('profile_image') ??
              profileImage);

      // Numeric fields handled safely
      final extractedVmid =
          safeInt(_getFromResponse('vmid') ?? _getFromResponse('VMID'));
      final extractedVuid = safeInt(_getFromResponse('vuid'));
      final extractedVbpid = safeInt(_getFromResponse('vbpid'));
      final extractedVcid = safeInt(_getFromResponse('vcid'));
      final extractedVsubid = safeInt(_getFromResponse('vsubid'));
      final extractedVpoid = safeInt(_getFromResponse('vpoid'));
      final extractedMtypeId = safeInt(_getFromResponse('mtypeId'));
      final extractedVmTypeId = safeInt(_getFromResponse('vmTypeId'));
      final extractedVpidpo = safeInt(_getFromResponse('vpidpo'));
      final extractedVpidbp = safeInt(_getFromResponse('vpidbp'));
      final extractedUnitid = safeInt(_getFromResponse('unitid'));
      final extractedSubunitid = safeInt(_getFromResponse('subunitid'));
      // production_type could be string sometimes
      final productionTypeVal = _getFromResponse('production_type_id') ??
          _getFromResponse('productionTypeId');
      final extractedProductionTypeId = safeInt(productionTypeVal);

      // Use transaction to insert first-user only
      await db.transaction((txn) async {
        // For testing purposes, clear existing data first
        await txn.delete('login_data');
        print('🗑️ Cleared existing login data for fresh test');

        final existingData = await txn.query('login_data');
        print('📊 Existing data count: ${existingData.length}');
        if (existingData.isNotEmpty) {
          print('🚫 Login table already contains data. Skipping insert');
          return;
        }

        final loginData = {
          'manager_name': safeString(_getFromResponse('fname') ??
              _getFromResponse('manager_name') ??
              _getFromResponse('managerName')),
          'profile_image': extractedProfileImage,
          'registered_movie': safeString(_getFromResponse('projectName') ??
              _getFromResponse('registered_movie')),
          'mobile_number': mobileNumber,
          'subUnitName': extractedSubUnitName,
          'password': password,
          'project_id': safeString(
              _getFromResponse('projectId') ?? _getFromResponse('projectid')),
          'production_type_id': extractedProductionTypeId,
          'production_house': safeString(_getFromResponse('productionHouse') ??
              _getFromResponse('production_house')),
          'vmid': extractedVmid,
          'login_date': DateTime.now().toIso8601String(),
          'vsid': safeString(
              _getFromResponse('vsid') ?? loginresponsebody?['vsid']),
          'vpid':
              safeString(_getFromResponse('vpid') ?? _getFromResponse('VPID')),
          'vuid': extractedVuid,
          'vbpid': extractedVbpid,
          'vcid': extractedVcid,
          'vsubid': extractedVsubid,
          'vpoid': extractedVpoid,
          'mtypeId': extractedMtypeId,
          'unitName': safeString(
              _getFromResponse('unitName') ?? _getFromResponse('unitname')),
          'vmTypeId': extractedVmTypeId,
          'idcardurl': safeString(_getFromResponse('idcardurl')),
          'vpidpo': extractedVpidpo,
          'vpidbp': extractedVpidbp,
          'unitid': extractedUnitid,
          'subunitid': extractedSubunitid,
          'platformlogo': safeString(_getFromResponse('platformlogo')),
          'isAgentt': (extractedUnitid == 18) ? 1 : 0,
          'driver': 0,
        };

        print('📝 Adding FIRST USER login data: $loginData');
        final insertResult = await txn.insert(
          'login_data',
          loginData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print(
            '🎉 FIRST USER login data saved to SQLite successfully with ID: $insertResult');
      });

      final savedData = await getActiveLoginData();
      print('🔍 Verification - Retrieved first user data: $savedData');
    } catch (e) {
      print('❌ Error saving login data: $e');
      if (e.toString().contains('database_closed')) {
        _database = null;
      }
    }
  }

  // Get active login data from SQLite (first user only)
  static Future<Map<String, dynamic>?> getActiveLoginData() async {
    try {
      final db = await database;
      await _createLoginTable(db); // Ensure table exists
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC', // Get the first user (lowest ID)
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return maps.first;
      }
      return null;
    } catch (e) {
      print('Error getting login data: $e');
      return null;
    }
  }

  // Get first user data (helper function)
  static Future<Map<String, dynamic>?> getFirstUserData() async {
    try {
      final db = await database;
      await _createLoginTable(db); // Ensure table exists
      final List<Map<String, dynamic>> maps = await db.query(
        'login_data',
        orderBy: 'id ASC', // Always get the first user
        limit: 1,
      );

      if (maps.isNotEmpty) {
        print(
            '👤 First user found: ${maps.first['manager_name']} (${maps.first['mobile_number']})');
        return maps.first;
      }
      print('🔍 No users found in database');
      return null;
    } catch (e) {
      print('Error getting first user data: $e');
      return null;
    }
  }

  // Test SQLite functionality
  static Future<void> testSQLite() async {
    try {
      print('🧪 Running SQLite test...');
      final db = await database;

      // Test basic query
      final result = await db.rawQuery('SELECT sqlite_version()');
      print('📊 SQLite Version: $result');

      // Test table existence
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='login_data'");
      print('🔍 Login table exists: ${tables.isNotEmpty}');

      if (tables.isNotEmpty) {
        // Test table structure
        final columns = await db.rawQuery('PRAGMA table_info(login_data)');
        print('📋 Table structure: $columns');
      }

      print('✅ SQLite test completed successfully');
    } catch (e) {
      print('❌ SQLite test failed: $e');
    }
  }

  // Update specific login data fields for driver response
  static Future<void> updateDriverLoginData(
    String projectName,
    String projectId,
    String productionHouse,
    int productionTypeId,
  ) async {
    print('🔄 updateDriverLoginData called');
    print('🔍 Input values:');
    print('  projectName: "$projectName"');
    print('  projectId: "$projectId"');
    print('  productionHouse: "$productionHouse"');

    try {
      print('🔄 Getting database connection...');
      final db = await database;
      await _createLoginTable(db); // Ensure table exists
      print('✅ Database connection obtained');

      // Get the first user's ID
      print('🔄 Getting first user data...');
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        final userId = firstUser['id'];
        print('✅ Found user with ID: $userId');

        // Show current data before update
        print('🔍 Current data before update:');
        print('  registered_movie: "${firstUser['registered_movie']}"');
        print('  project_id: "${firstUser['project_id']}"');
        print('  production_house: "${firstUser['production_house']}"');

        // Update the first user's data
        print('🔄 Performing database update...');
        final updateCount = await db.update(
          'login_data',
          {
            'registered_movie': projectName,
            'project_id': projectId,
            'production_house': productionHouse,
            'production_type_id': productionTypeId,
          },
          where: 'id = ?',
          whereArgs: [userId],
        );

        print('📊 Update count: $updateCount');

        if (updateCount > 0) {
          print('✅ Driver login data updated successfully');
          print('📝 Updated registered_movie: $projectName');
          print('📝 Updated project_id: $projectId');
          print('📝 Updated production_house: $productionHouse');

          // Verify the update by reading back the data
          final updatedUser = await getFirstUserData();
          if (updatedUser != null) {
            print('🔍 Verified updated data:');
            print('  registered_movie: "${updatedUser['registered_movie']}"');
            print('  project_id: "${updatedUser['project_id']}"');
            print('  production_house: "${updatedUser['production_house']}"');
          }
        } else {
          print('⚠️ Failed to update login data - updateCount is 0');
        }
      } else {
        print('⚠️ No login data found to update - firstUser is null');
      }
    } catch (e) {
      print('❌ Error updating driver login data: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $e');
    }

    print('🏁 updateDriverLoginData completed');
  }

  // Update driver field based on navigation route
  static Future<void> updateDriverField(bool isDriver) async {
    try {
      print('🔄 Updating driver field to: $isDriver');
      final db = await database;
      await _createLoginTable(db); // Ensure table exists

      // Get the first user's ID
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        final userId = firstUser['id'];

        // Update the driver field
        final updateCount = await db.update(
          'login_data',
          {'driver': isDriver ? 1 : 0},
          where: 'id = ?',
          whereArgs: [userId],
        );

        if (updateCount > 0) {
          print('✅ Driver field updated successfully to: $isDriver');
        } else {
          print('⚠️ Failed to update driver field');
        }
      } else {
        print('⚠️ No user found to update driver field');
      }
    } catch (e) {
      print('❌ Error updating driver field: $e');
    }
  }

  // Clear first user login data (removes the registered first user)
  static Future<void> clearLoginData() async {
    try {
      final db = await database;
      await _createLoginTable(db); // Ensure table exists

      // Get first user info before deleting
      final firstUser = await getFirstUserData();
      if (firstUser != null) {
        print(
            '🗑️ Clearing first user: ${firstUser['manager_name']} (${firstUser['mobile_number']})');
      }

      // Delete all records (reset for new first user)
      await db.delete('login_data');
      print(
          '✅ First user login data cleared successfully - Ready for new first user registration');
    } catch (e) {
      print('❌ Error clearing login data: $e');
    }
  }

  // Close database connection
  static Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('🔒 Database closed');
    }
  }
}

