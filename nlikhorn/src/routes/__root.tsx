import { NavBar } from "@/components/custom/NavBar";
import { ColorModeButton } from "@/components/ui/color-mode";
import { Center, Container } from "@chakra-ui/react";
import { Link, Outlet, createRootRoute } from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/router-devtools";

export const Route = createRootRoute({
	component: () => (
		<>
			<Center height={"100svh"}>
				<Container
					maxWidth={"xl"}
					boxSize={"full"}
					padding={2}
					position={"relative"}
				>
					<Link to="/" className="[&.active]:font-bold">
						Home
					</Link>{" "}
					<Link to="/earn" className="[&.active]:font-bold">
						Earn
					</Link>
					<ColorModeButton />
					<Outlet />
					<NavBar />
				</Container>
			</Center>

			{import.meta.env.DEV && <TanStackRouterDevtools />}
		</>
	),
});
