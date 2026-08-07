import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

export function AppHeader() {
  return (
    <View style={styles.header}>
      <View style={styles.copy}>
        <Text style={styles.eyebrow}>SNORER · ANDROID EERST</Text>
        <Text style={styles.title}>Luister naar je nacht.</Text>
        <Text style={styles.subtitle}>
          Neem slaapgeluiden op en luister ze lokaal terug. Geen upload, geen automatische detectie.
        </Text>
      </View>
      <View style={styles.localBadge}>
        <View style={styles.localDot} />
        <Text style={styles.localBadgeText}>Lokaal</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 14,
  },
  copy: {
    flex: 1,
  },
  eyebrow: {
    color: colors.primary,
    fontSize: 12,
    fontWeight: '800',
    letterSpacing: 1.4,
  },
  title: {
    color: colors.text,
    fontSize: 34,
    lineHeight: 39,
    fontWeight: '800',
    letterSpacing: -0.8,
    marginTop: 8,
  },
  subtitle: {
    color: colors.muted,
    fontSize: 15,
    lineHeight: 22,
    marginTop: 10,
    maxWidth: 330,
  },
  localBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 7,
    marginTop: 3,
  },
  localDot: {
    width: 7,
    height: 7,
    borderRadius: 7,
    backgroundColor: colors.primary,
    marginRight: 6,
  },
  localBadgeText: {
    color: colors.text,
    fontSize: 12,
    fontWeight: '700',
  },
});
