import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

export function AppFooter() {
  return (
    <View style={styles.footer}>
      <Text style={styles.title}>Privé by default</Text>
      <Text style={styles.text}>
        Audio en labels blijven in de documentmap van Snorer. De MVP gebruikt geen cloudanalyse, account of automatische detectie.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  footer: {
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 17,
    marginTop: 5,
  },
  title: {
    color: colors.text,
    fontSize: 13,
    fontWeight: '800',
  },
  text: {
    color: colors.muted,
    fontSize: 12,
    lineHeight: 18,
    marginTop: 5,
  },
});
