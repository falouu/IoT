package pl.mfalkowski.NodeMCUtests;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.mustache.MustacheProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;
import org.springframework.web.reactive.function.server.HandlerFunction;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerRequestExtensionsKt;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.publisher.SignalType;
import reactor.util.Logger;
import reactor.util.Loggers;
import reactor.util.function.Tuple2;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.NON_PRIVATE;
import static com.fasterxml.jackson.annotation.PropertyAccessor.FIELD;
import static org.springframework.web.reactive.function.BodyInserters.fromObject;
import static org.springframework.web.reactive.function.server.RequestPredicates.GET;
import static org.springframework.web.reactive.function.server.RequestPredicates.POST;
import static org.springframework.web.reactive.function.server.RouterFunctions.route;

@SpringBootApplication
public class NodeMcuTestsApplication {

	private final Logger logger = Loggers.getLogger(NodeMcuTestsApplication.class);
	private final State state = new State();

    enum WifiStatus {
        WL_IDLE_STATUS,
        WL_NO_SSID_AVAIL,
        WL_SCAN_COMPLETED,
        WL_CONNECTED,
        WL_CONNECT_FAILED,
        WL_CONNECTION_LOST,
        WL_DISCONNECTED
    }

    static class AdminData {
	    static class WifiStatusData {
	        String value;
	        boolean isCurrent;
        }

	    List<WifiStatusData> wifiStatuses;
	    String wifiStatus;

	    List<String> templateNames;
    }

    static class State {
	    String ssid;
	    String password;
	    String status = "";
    }

    static class Status {
        Wifi wifi;

        static class Wifi {
            String ssid;
            String status;
        }
    }

    private final MustacheProperties mustacheProperties;

    @Autowired
    public NodeMcuTestsApplication(MustacheProperties mustacheProperties) {
        this.mustacheProperties = mustacheProperties;
    }


    public static void main(String[] args) {
		SpringApplication.run(NodeMcuTestsApplication.class, args);
	}

	private HandlerFunction<ServerResponse> statusHandler =
        request ->
            ServerResponse.ok().body(
                Mono.just(new Status())
                    .doOnNext(s -> s.wifi = new Status.Wifi())
                    .doOnNext(s -> s.wifi.status = state.status)
                    .doOnNext(s -> s.wifi.ssid = state.ssid),
                Status.class
            );


	private HandlerFunction<ServerResponse> connectHandler =
		request ->
			request.formData()
                .flatMap(body ->
                    Mono.just(body.getFirst("ssid"))
                        .filter(Objects::nonNull)
                        .doOnNext(s -> logger.info("SSID: {}", s))
                        .doOnNext(s -> state.ssid = s)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No ssid in request!")))
                        .then(Mono.just(body.getFirst("password")))
                        .filter(Objects::nonNull)
                        .doOnNext(p -> logger.info("password: {}", p))
                        .doOnNext(p -> state.password = p)
                        .switchIfEmpty(Mono.fromRunnable(() -> logger.info("No password in request!")))
                )
                .then(ServerResponse.seeOther(URI.create("/connecting")).build());

	private HandlerFunction<ServerResponse> adminGetHandler =
        request ->
            Mono.just(new AdminData())
                .zipWith(
                    Flux.fromArray(WifiStatus.values())
                        .map(Enum::name)
                        .flatMap(s -> Mono
                            .just(new AdminData.WifiStatusData())
                            .doOnNext(sd -> sd.value = s)
                            .doOnNext(sd -> sd.isCurrent = (Objects.equals(s, state.status)))
                        )
                        .collectList()
                )
                .doOnNext(t -> t.getT1().wifiStatuses = t.getT2())
                .map(Tuple2::getT1)
                .doOnNext(data -> data.wifiStatus = state.status)
                .flatMap(data -> getTemplateNames()
                    .collectList()
                    .doOnNext(templateNames -> data.templateNames = templateNames)
                    .map(t -> data)
                )
                .map(data -> Collections.singletonMap("data", data))
                .flatMap(model -> ServerResponse.ok().render("admin/admin", model));

	private HandlerFunction<ServerResponse> adminPostHandler =
        request ->
            request.formData()
                .doOnNext(form -> state.status = form.getFirst("wifiStatus"))
                .then(ServerResponse.seeOther(URI.create("/admin")).build());

	private HandlerFunction<ServerResponse> adminGetTemplateHandler =
        request ->
            Flux.fromStream(request.queryParam("name").stream())
                .singleOrEmpty()
                .materialize()
                .flatMap(signal ->
                    signal.getType() == SignalType.ON_COMPLETE
                        ? ServerResponse.badRequest().body(fromObject("'name' query param is missing!"))
                        : getTemplate(signal.get())
                            .flatMap(content -> ServerResponse.ok()
                                .contentType(MediaType.TEXT_PLAIN)
                                .body(fromObject(content))
                            )
                            .onErrorResume(error -> ServerResponse
                                .status(HttpStatus.NOT_FOUND)
                                .body(fromObject("Template '" + signal.get() + "' not found!"))
                            )
                );

    @Bean
    RouterFunction<ServerResponse> routes()  {
		return route(GET("/status"), statusHandler)
			.and(
				route(GET("/"), request -> ServerResponse.ok().render("root"))
			)
            .and(route(GET("/connecting"), request -> ServerResponse.ok().render("connecting")))
			.and(route(POST("/connect"), connectHandler))
            .and(route(GET("/admin"), adminGetHandler))
            .and(route(POST("/admin"), adminPostHandler))
            .and(route(GET("/admin/template"), adminGetTemplateHandler));
    }

    @Bean
	ObjectMapper objectMapper(Jackson2ObjectMapperBuilder builder) {
		return builder.build()
			.setVisibility(FIELD, NON_PRIVATE);
	}

	private Flux<String> getTemplateNames() {
        String suffix = mustacheProperties.getSuffix();

        PathMatchingResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        List<Resource> resources;
        try {
            resources = Arrays.asList(resolver.getResources("classpath:/templates/*" + suffix));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        return Flux.fromIterable(resources)
            .map(Resource::getFilename)
            .map(filename -> filename.substring(0, filename.lastIndexOf('.')));
    }

    private Mono<String> getTemplate(String template) {

        return Mono
            .fromCallable(() ->
                this.getClass().getResource("/templates/" + template + mustacheProperties.getSuffix())
            )
            .map(url -> {
                try {
                    return Files.lines(Paths.get(url.toURI()));
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
            })
            .single()
            .flatMapMany(Flux::fromStream)
            .collect(Collectors.joining("\n"));
    }
}
