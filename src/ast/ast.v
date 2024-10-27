module ast

import token
import strconv
import errors_df




type EvalOutput = string | int | f64

__global identifier_value_map = map[string]EvalOutput{}


pub interface Node {
	eval() !EvalOutput
}

fn check_eval_name(output EvalOutput) string {
	match output {
		string {
			return 'str'
		}
		else {
			return 'num'
		}
	}
	return ''
}

fn error_gen(while string, extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    while
		when:     extra_info
		path:     ''
		cur_line: 0
		cur_col:  0
		error:    error_data
	}
}

pub struct Chunk {
pub mut:
	body  []Node
	range []i64
}

pub enum LitrealType {
	integer
	floating_point
	str
	boolean
	null
}

pub struct Litreal {
pub mut:
	hint  LitrealType
	value string
}

fn (li Litreal) eval() !EvalOutput {
	match li.hint {
		.integer {
			return EvalOutput(li.value.int())
		}
		.floating_point {
			return EvalOutput(strconv.atof_quick(li.value))
		}
		.str {
			return li.value
		}
		.boolean {
			if li.value == 'true' {
				return 1
			}
			return 0
		}
		.null {
			return 0
		}
	}
	return error_gen('eval', 'litreal', errors_df.ErrorUnsupported{})
}

pub struct Binary {
pub mut:
	operator string
	left     Node
	right    Node
}

fn (bi Binary) eval() !EvalOutput {
	left_eval := bi.left.eval()!
	right_eval := bi.right.eval()!

	if (left_eval is f64 && right_eval is f64) || (left_eval is int && right_eval is int) {
		if bi.operator in num_ops {
			return num_ops[bi.operator](left_eval, right_eval)
		} else {
			// Unsupported operator
			return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
				type_of_value: 'num'
				supported:     num_ops.keys()
				found:         bi.operator
			})
		}
	} else if left_eval is string {
		match right_eval {
			string {
				if bi.operator != '+' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['+']
						found:         bi.operator
					})
				}
				return '${left_eval as string}${right_eval as string}'

			}
			int {
				if bi.operator != '*' {
					return error_gen('eval', 'binary', errors_df.ErrorBinaryOperationUnsupported{
						type_of_value: 'str'
						supported:     ['+']
						found:         bi.operator
					})
				}
				return errors_df.gen_letter(left_eval, right_eval)
			}
			else {
				return error_gen('eval', 'binary', errors_df.ErrorEvalTypeMisMatch{
					left:  check_eval_name(left_eval)
					right: check_eval_name(right_eval)
					op:    bi.operator
				})
			}
		}
	}
	
	return error_gen('eval', 'binary', errors_df.ErrorUnsupported{})
}


pub struct Identifier {
pub mut:
	value string
	from string
}


fn (i Identifier) eval() !EvalOutput {
	return identifier_value_map["${i.from}_${i.value}"] or {
		return error_gen('eval', 'identifier', errors_df.ErrorUndefinedToken{ token: i.value })
	}
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}


pub struct CallExpression {
pub mut:
	base      token.Identifier
	arguments []Node
}

fn (ce CallExpression) eval() !EvalOutput {
	match ce.base.reserved {
		'print' {
			print_reserved_function(ce.arguments, false)!
		}
		'println' {
			print_reserved_function(ce.arguments, true)!
		}
		else {
			return error_gen('eval', 'call_exp', errors_df.ErrorUndefinedToken{ token: ce.base.value })
		}
	}
	// for args in ce.arguments {
	// 	args.eval()!
	// }

	return EvalOutput(0)
	// return error_gen('eval', 'call_exp', errors_df.ErrorUnsupported{})
}

// type Stat = Node
