import 'package:cloud_functions/cloud_functions.dart';

const firebaseFunctionsRegion = 'africa-south1';
const firebaseFunctionsEmulatorPort = 15001;

FirebaseFunctions firebaseFunctionsForApp() =>
    FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

void configureFirebaseFunctionsEmulator(String host, int port) {
  firebaseFunctionsForApp().useFunctionsEmulator(host, port);
}
