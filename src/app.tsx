import '../globals.css';

import { SafeAreaProvider } from 'react-native-safe-area-context';

import { GluestackUIProvider } from '../components/ui/gluestack-ui-provider';
import { RecordingScreen } from './features/recordings/recording-screen';

export default function App() {
  return (
    <GluestackUIProvider mode="system">
      <SafeAreaProvider>
        <RecordingScreen />
      </SafeAreaProvider>
    </GluestackUIProvider>
  );
}
