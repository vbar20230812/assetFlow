// /home/user/myapp/dataconnect-generated/dart/default_connector/default.dart

library ;

// Import the local firebase_data_connect.dart
import 'package:myapp/services/firebase_data_connect.dart'; // Adjust if your package name is different
import 'dart:convert';

class DefaultConnector {
  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-central1',
    'default',
    'assetflow-fire1',
  );

  DefaultConnector({required this.dataConnect});
  
  static DefaultConnector get instance {
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}