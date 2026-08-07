import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

interface ErrorCardProps {
  message: string;
}

export function ErrorCard({ message }: ErrorCardProps) {
  return (
    <View style={styles.card} accessibilityLiveRegion="polite">
      <Text style={styles.title}>Er ging iets mis</Text>
      <Text style={styles.text}>{message}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.errorBackground,
    borderRadius: 17,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.errorBorder,
  },
  title: {
    color: colors.danger,
    fontSize: 14,
    fontWeight: '800',
  },
  text: {
    color: colors.errorText,
    fontSize: 13,
    lineHeight: 19,
    marginTop: 4,
  },
});
