/**
 * src/ui/components/alert.tsx — Flash alert component stub
 * Cycle 6 RED phase.
 */

export type AlertVariant = "success" | "warning" | "error" | "info";

export interface AlertProps {
  variant: AlertVariant;
  message: string;
}

// RED stub — not implemented
export function Alert(_props: AlertProps): unknown {
  throw new Error("not implemented: Alert");
}
