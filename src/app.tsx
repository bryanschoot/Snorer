import { SafeAreaProvider } from 'react-native-safe-area-context';

import { RecordingScreen } from './features/recordings/recording-screen';

export default function App() {
  return (
    <SafeAreaProvider>
      <RecordingScreen />
    </SafeAreaProvider>
  );
}
