import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

export function ScopeCard() {
  return (
    <View style={styles.card}>
      <View style={styles.mark}>
        <Text style={styles.markText}>✓</Text>
      </View>
      <View style={styles.copy}>
        <Text style={styles.title}>Jij bepaalt wat je hoort</Text>
        <Text style={styles.text}>
          Snurken en praten in je slaap worden in deze MVP niet automatisch herkend. Je kunt een opname achteraf zelf labelen.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.surfaceSoft,
    borderRadius: 20,
    padding: 16,
    gap: 12,
  },
  mark: {
    width: 26,
    height: 26,
    borderRadius: 26,
    backgroundColor: colors.primaryDark,
    alignItems: 'center',
    justifyContent: 'center',
  },
  markText: {
    color: colors.text,
    fontWeight: '900',
  },
  copy: {
    flex: 1,
  },
  title: {
    color: colors.text,
    fontSize: 14,
    fontWeight: '800',
  },
  text: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    marginTop: 4,
  },
});
