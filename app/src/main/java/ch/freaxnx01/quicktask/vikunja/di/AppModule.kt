package ch.freaxnx01.quicktask.vikunja.di

import ch.freaxnx01.quicktask.vikunja.data.SecureStorage
import ch.freaxnx01.quicktask.vikunja.data.VikunjaApi
import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideJson(): Json = Json { ignoreUnknownKeys = true }

    @Provides
    @Singleton
    fun provideOkHttpClient(secureStorage: SecureStorage): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor { chain ->
                val original = chain.request()
                val token = secureStorage.apiToken ?: ""
                val baseUrl = secureStorage.instanceUrl ?: "http://localhost"

                // Rewrite URL to use the configured base URL
                val originalUrl = original.url
                val base = baseUrl.toHttpUrl()
                val newUrl = originalUrl.newBuilder()
                    .scheme(base.scheme)
                    .host(base.host)
                    .port(base.port)
                    .build()

                val request = original.newBuilder()
                    .url(newUrl)
                    .addHeader("Authorization", "Bearer $token")
                    .build()
                chain.proceed(request)
            }
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, json: Json): Retrofit {
        return Retrofit.Builder()
            .baseUrl("http://localhost/") // Placeholder, interceptor rewrites this
            .client(okHttpClient)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
    }

    @Provides
    @Singleton
    fun provideVikunjaApi(retrofit: Retrofit): VikunjaApi {
        return retrofit.create(VikunjaApi::class.java)
    }
}
