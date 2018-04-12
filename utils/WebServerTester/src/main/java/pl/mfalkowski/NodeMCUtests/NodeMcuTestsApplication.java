package pl.mfalkowski.NodeMCUtests;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.util.MultiValueMap;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;
import reactor.util.Logger;
import reactor.util.Loggers;

import java.net.ResponseCache;
import java.net.URI;
import java.util.Map;
import java.util.Objects;

import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RequestPredicates.POST;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class NodeMcuTestsApplication {

	private Logger logger = Loggers.getLogger(NodeMcuTestsApplication.class);

	public static void main(String[] args) {
		SpringApplication.run(NodeMcuTestsApplication.class, args);
	}

	private HandlerFunction<ServerResponse> statusHandler =
        request ->
            ServerResponse.ok().body(BodyInserters.fromObject("OK"));

	private HandlerFunction<ServerResponse> connectHandler =
		request ->
			request.bodyToMono(new ParameterizedTypeReference<MultiValueMap<String, String>>() {})
                .flatMap(body ->
                    Mono.just(body.getFirst("ssid"))
                        .filter(Objects::nonNull)
                        .doOnNext(s -> logger.info("SSID: {}", s))
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No ssid in request!")))
                        .then(Mono.just(body.getFirst("password")))
                        .filter(Objects::nonNull)
                        .doOnNext(p -> logger.info("password: {}", p))
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No password in request!")))
                )
                .then(ServerResponse.seeOther(URI.create("/connecting")).build());


    @Bean
    RouterFunction<ServerResponse> routes()  {
		return route(GET("/status"), statusHandler)
			.and(
				route(GET("/dupa"), request -> ServerResponse.ok().render("dupa"))
			)
			.and(
				route(GET("/"), request -> ServerResponse.ok().render("root"))
			)
            .and(route(GET("/connecting"), request -> ServerResponse.ok().render("connecting")))
			.and(route(POST("/connect"), connectHandler));
    }


}
