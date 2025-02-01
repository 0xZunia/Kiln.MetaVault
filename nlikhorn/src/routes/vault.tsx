import { createFileRoute } from "@tanstack/react-router";
import { useContext } from "react";
import { HeadingContext } from "./__root";

export const Route = createFileRoute("/vault")({
	component: RouteComponent,
});

function RouteComponent() {
	const { setHeading } = useContext(HeadingContext);
	setHeading("Vault");

	return <div>Hello "/vault"!</div>;
}
