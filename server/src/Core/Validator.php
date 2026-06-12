<?php

declare(strict_types=1);

namespace App\Core;

/**
 * Tiny declarative validator producing per-field error messages.
 *
 * Supported rules: required, email, string, numeric, integer,
 * min:<n> (string length or numeric value), max:<n>,
 * in:<a,b,c>, date (Y-m-d), time (HH:MM), boolean.
 */
final class Validator
{
    private array $errors = [];

    private function __construct(private array $data, private array $rules)
    {
    }

    public static function make(array $data, array $rules): self
    {
        $v = new self($data, $rules);
        $v->run();
        return $v;
    }

    public function fails(): bool
    {
        return $this->errors !== [];
    }

    public function errors(): array
    {
        return $this->errors;
    }

    /**
     * Abort the request with the documented validation envelope on failure.
     */
    public static function validateOrAbort(array $data, array $rules): void
    {
        $v = self::make($data, $rules);
        if ($v->fails()) {
            Response::validationError($v->errors());
        }
    }

    private function run(): void
    {
        foreach ($this->rules as $field => $ruleString) {
            $rules = is_array($ruleString) ? $ruleString : explode('|', $ruleString);
            $value = $this->data[$field] ?? null;
            $isEmpty = $value === null || $value === '' || $value === [];
            $required = in_array('required', $rules, true);

            if ($required && $isEmpty) {
                $this->errors[$field] = self::label($field) . ' is required.';
                continue;
            }
            if ($isEmpty) {
                continue; // optional + empty: skip other rules
            }

            foreach ($rules as $rule) {
                if ($rule === 'required') {
                    continue;
                }
                $param = null;
                if (str_contains($rule, ':')) {
                    [$rule, $param] = explode(':', $rule, 2);
                }
                $error = $this->check($field, $value, $rule, $param);
                if ($error !== null) {
                    $this->errors[$field] = $error;
                    break;
                }
            }
        }
    }

    private function check(string $field, mixed $value, string $rule, ?string $param): ?string
    {
        $label = self::label($field);
        switch ($rule) {
            case 'email':
                if (!is_string($value) || filter_var($value, FILTER_VALIDATE_EMAIL) === false) {
                    return $label . ' must be a valid email address.';
                }
                break;
            case 'string':
                if (!is_string($value)) {
                    return $label . ' must be a string.';
                }
                break;
            case 'numeric':
                if (!is_numeric($value)) {
                    return $label . ' must be a number.';
                }
                break;
            case 'integer':
                if (filter_var($value, FILTER_VALIDATE_INT) === false) {
                    return $label . ' must be an integer.';
                }
                break;
            case 'boolean':
                if (!is_bool($value) && !in_array($value, [0, 1, '0', '1', 'true', 'false'], true)) {
                    return $label . ' must be a boolean.';
                }
                break;
            case 'min':
                if (is_numeric($value) && !is_string($value)) {
                    if ($value + 0 < (float)$param) {
                        return $label . ' must be at least ' . $param . '.';
                    }
                } elseif (mb_strlen((string)$value) < (int)$param) {
                    return $label . ' must be at least ' . $param . ' characters.';
                }
                break;
            case 'max':
                if (is_numeric($value) && !is_string($value)) {
                    if ($value + 0 > (float)$param) {
                        return $label . ' must be at most ' . $param . '.';
                    }
                } elseif (mb_strlen((string)$value) > (int)$param) {
                    return $label . ' must be at most ' . $param . ' characters.';
                }
                break;
            case 'in':
                $allowed = explode(',', (string)$param);
                if (!in_array((string)$value, $allowed, true)) {
                    return $label . ' must be one of: ' . implode(', ', $allowed) . '.';
                }
                break;
            case 'date':
                if (!is_string($value) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $value) || !strtotime($value)) {
                    return $label . ' must be a valid date (YYYY-MM-DD).';
                }
                break;
            case 'time':
                if (!is_string($value) || !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $value)) {
                    return $label . ' must be a valid time (HH:MM).';
                }
                break;
        }
        return null;
    }

    private static function label(string $field): string
    {
        return ucfirst(str_replace('_', ' ', $field));
    }
}
