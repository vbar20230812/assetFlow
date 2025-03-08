// /home/user/myapp/lib/services/default.dart
library;

import 'firebase_data_connect.dart'; // This is correct for importing from the same directory
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