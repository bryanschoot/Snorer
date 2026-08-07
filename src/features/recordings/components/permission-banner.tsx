import { StyleSheet, Text, View } from 'react-native';

import { colors } from '../../../theme';

export function PermissionBanner() {
  return (
    <View style={styles.banner} accessibilityLiveRegion="polite">
      <Text style={styles.title}>Microfoontoegang staat nog uit</Text>
      <Text style={styles.text}>
        Snorer kan pas opnemen nadat Android de microfoon toestemming geeft. Er wordt niets naar een server gestuurd.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  banner: {
    backgroundColor: colors.warningBackground,
    borderColor: colors.warningBorder,
    borderWidth: 1,
    borderRadius: 18,
    padding: 16,
  },
  title: {
    color: colors.warning,
    fontSize: 15,
    fontWeight: '800',
  },
  text: {
    color: colors.warningText,
    fontSize: 13,
    lineHeight: 19,
    marginTop: 6,
  },
});
