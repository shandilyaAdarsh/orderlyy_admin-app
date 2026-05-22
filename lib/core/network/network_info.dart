import 'package:connectivity_plus/connectivity_plus.dart';
import 'network_info_io.dart' if (dart.library.html) 'network_info_web.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectionChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    final statusList = await _connectivity.checkConnectivity();
    if (statusList.contains(ConnectivityResult.none)) {
      return false;
    }
    return await checkConnection();
  }

  @override
  Stream<bool> get onConnectionChanged {
    return _connectivity.onConnectivityChanged.asyncMap((statusList) async {
      if (statusList.contains(ConnectivityResult.none)) {
        return false;
      }
      return await checkConnection();
    }).distinct();
  }
}
