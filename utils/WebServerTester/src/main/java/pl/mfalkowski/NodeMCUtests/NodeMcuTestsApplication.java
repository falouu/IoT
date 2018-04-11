package pl.mfalkowski.NodeMCUtests;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class NodeMcuTestsApplication {

	public static void main(String[] args) {
		SpringApplication.run(NodeMcuTestsApplication.class, args);
	}

	private HandlerFunction<ServerResponse> statusHandler =
        request ->
            ServerResponse.ok().body(BodyInserters.fromObject("OK"));

	@Bean
	RouterFunction<ServerResponse> statusRoute()  {
		return route(GET("/status"), statusHandler);
	}

    @Bean
    RouterFunction<ServerResponse> routes()  {
        return route(GET("/dupa"), request -> ServerResponse.ok().render("dupa"))
			.and(
				route(GET("/"), request -> ServerResponse.ok().render("root"))
			);
    }


}
