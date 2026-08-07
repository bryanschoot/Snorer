import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

export function EmptyRecordingState() {
  return (
    <View style={styles.card}>
      <View style={styles.circle}>
        <View style={styles.wave} />
      </View>
      <Text style={styles.title}>Nog geen nacht vastgelegd</Text>
      <Text style={styles.text}>
        Je eerste opname verschijnt hier zodra je de sessie stopt. Alles blijft op dit apparaat.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 22,
    paddingHorizontal: 28,
    paddingVertical: 30,
    borderWidth: 1,
    borderColor: colors.border,
  },
  circle: {
    width: 56,
    height: 56,
    borderRadius: 56,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  wave: {
    width: 22,
    height: 17,
    borderTopWidth: 2,
    borderBottomWidth: 2,
    borderColor: colors.primary,
    transform: [{ skewX: '-18deg' }],
  },
  title: {
    color: colors.text,
    fontSize: 17,
    fontWeight: '800',
    marginTop: 16,
  },
  text: {
    color: colors.muted,
    fontSize: 13,
    lineHeight: 19,
    textAlign: 'center',
    marginTop: 7,
  },
});
