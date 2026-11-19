-- Idempotent repeat cleanup recorded in remote migration history.
drop function if exists private.save_network_switch_with_ports(jsonb,jsonb);
revoke usage on schema private from authenticated;
