/**
 * src/ui/components/alert.tsx — Flash alert component
 * Cycle 6 GREEN phase.
 */

export type AlertVariant = "success" | "warning" | "error" | "info";

export interface AlertProps {
  variant: AlertVariant;
  message: string;
}

export function Alert(props: AlertProps): string {
  const { variant, message } = props;
  return `<div class="alert alert-${variant}" role="alert">${message}</div>`;
}
